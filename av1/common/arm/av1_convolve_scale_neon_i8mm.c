/*
 * Copyright (c) 2024, Alliance for Open Media. All rights reserved
 *
 * This source code is subject to the terms of the BSD 2 Clause License and
 * the Alliance for Open Media Patent License 1.0. If the BSD 2 Clause License
 * was not distributed with this source code in the LICENSE file, you can
 * obtain it at www.aomedia.org/license/software. If the Alliance for Open
 * Media Patent License 1.0 was not distributed with this source code in the
 * PATENTS file, you can obtain it at www.aomedia.org/license/patent.
 */

#include <assert.h>
#include <arm_neon.h>

#include "config/aom_config.h"
#include "config/av1_rtcd.h"

#include "aom_dsp/arm/mem_neon.h"
#include "aom_dsp/arm/transpose_neon.h"
#include "av1/common/arm/convolve_scale_neon.h"

static INLINE int16x4_t convolve8_4_h(const uint8x8_t s0, const uint8x8_t s1,
                                      const uint8x8_t s2, const uint8x8_t s3,
                                      const int8x8_t filter,
                                      const int32x4_t horiz_const) {
  const int8x16_t filters = vcombine_s8(filter, filter);

  uint8x16_t s01 = vcombine_u8(s0, s1);
  uint8x16_t s23 = vcombine_u8(s2, s3);

  int32x4_t sum01 = vusdotq_s32(horiz_const, s01, filters);
  int32x4_t sum23 = vusdotq_s32(horiz_const, s23, filters);

  int32x4_t sum = vpaddq_s32(sum01, sum23);

  // We halved the filter values so -1 from right shift.
  return vshrn_n_s32(sum, ROUND0_BITS - 1);
}

static INLINE int16x8_t convolve8_8_h(const uint8x8_t s0, const uint8x8_t s1,
                                      const uint8x8_t s2, const uint8x8_t s3,
                                      const uint8x8_t s4, const uint8x8_t s5,
                                      const uint8x8_t s6, const uint8x8_t s7,
                                      const int8x8_t filter,
                                      const int32x4_t horiz_const) {
  const int8x16_t filters = vcombine_s8(filter, filter);

  uint8x16_t s01 = vcombine_u8(s0, s1);
  uint8x16_t s23 = vcombine_u8(s2, s3);
  uint8x16_t s45 = vcombine_u8(s4, s5);
  uint8x16_t s67 = vcombine_u8(s6, s7);

  int32x4_t sum01 = vusdotq_s32(horiz_const, s01, filters);
  int32x4_t sum23 = vusdotq_s32(horiz_const, s23, filters);
  int32x4_t sum45 = vusdotq_s32(horiz_const, s45, filters);
  int32x4_t sum67 = vusdotq_s32(horiz_const, s67, filters);

  int32x4_t sum0123 = vpaddq_s32(sum01, sum23);
  int32x4_t sum4567 = vpaddq_s32(sum45, sum67);

  // We halved the filter values so -1 from right shift.
  return vcombine_s16(vshrn_n_s32(sum0123, ROUND0_BITS - 1),
                      vshrn_n_s32(sum4567, ROUND0_BITS - 1));
}

static INLINE void convolve_horiz_scale_neon_i8mm(const uint8_t *src,
                                                  int src_stride, int16_t *dst,
                                                  int dst_stride, int w, int h,
                                                  const int16_t *x_filter,
                                                  const int subpel_x_qn,
                                                  const int x_step_qn) {
  DECLARE_ALIGNED(16, int16_t, temp[8 * 8]);
  const int bd = 8;
  // A shim of 1 << (ROUND0_BITS - 1) enables us to use non-rounding
  // shifts - which are generally faster than rounding shifts on modern CPUs.
  // Divide the total by 4: we halved the filter values and will use a pairwise
  // add in the convolution kernel.
  const int32x4_t horiz_offset = vdupq_n_s32(
      ((1 << (bd + FILTER_BITS - 1)) + (1 << (ROUND0_BITS - 1))) >> 2);

  if (w == 4) {
    do {
      int x_qn = subpel_x_qn;

      // Process a 4x4 tile.
      for (int r = 0; r < 4; r++) {
        const uint8_t *const s = &src[x_qn >> SCALE_SUBPEL_BITS];

        const ptrdiff_t filter_offset =
            SUBPEL_TAPS * ((x_qn & SCALE_SUBPEL_MASK) >> SCALE_EXTRA_BITS);
        // Filter values are all even so halve them to fit in int8_t.
        const int8x8_t filter =
            vshrn_n_s16(vld1q_s16(x_filter + filter_offset), 1);

        uint8x8_t t0, t1, t2, t3;
        load_u8_8x4(s, src_stride, &t0, &t1, &t2, &t3);

        int16x4_t d0 = convolve8_4_h(t0, t1, t2, t3, filter, horiz_offset);

        vst1_s16(&temp[r * 4], d0);
        x_qn += x_step_qn;
      }

      // Transpose the 4x4 result tile and store.
      int16x4_t d0, d1, d2, d3;
      load_s16_4x4(temp, 4, &d0, &d1, &d2, &d3);

      transpose_elems_inplace_s16_4x4(&d0, &d1, &d2, &d3);

      store_s16_4x4(dst, dst_stride, d0, d1, d2, d3);

      dst += 4 * dst_stride;
      src += 4 * src_stride;
      h -= 4;
    } while (h > 0);
  } else {
    do {
      int x_qn = subpel_x_qn;
      int16_t *d = dst;
      int width = w;

      do {
        // Process an 8x8 tile.
        for (int r = 0; r < 8; r++) {
          const uint8_t *const s = &src[(x_qn >> SCALE_SUBPEL_BITS)];

          const ptrdiff_t filter_offset =
              SUBPEL_TAPS * ((x_qn & SCALE_SUBPEL_MASK) >> SCALE_EXTRA_BITS);
          // Filter values are all even so halve them to fit in int8_t.
          const int8x8_t filter =
              vshrn_n_s16(vld1q_s16(x_filter + filter_offset), 1);

          uint8x8_t t0, t1, t2, t3, t4, t5, t6, t7;
          load_u8_8x8(s, src_stride, &t0, &t1, &t2, &t3, &t4, &t5, &t6, &t7);

          int16x8_t d0 = convolve8_8_h(t0, t1, t2, t3, t4, t5, t6, t7, filter,
                                       horiz_offset);

          vst1q_s16(&temp[r * 8], d0);

          x_qn += x_step_qn;
        }

        // Transpose the 8x8 result tile and store.
        int16x8_t d0, d1, d2, d3, d4, d5, d6, d7;
        load_s16_8x8(temp, 8, &d0, &d1, &d2, &d3, &d4, &d5, &d6, &d7);

        transpose_elems_inplace_s16_8x8(&d0, &d1, &d2, &d3, &d4, &d5, &d6, &d7);

        store_s16_8x8(d, dst_stride, d0, d1, d2, d3, d4, d5, d6, d7);

        d += 8;
        width -= 8;
      } while (width != 0);

      dst += 8 * dst_stride;
      src += 8 * src_stride;
      h -= 8;
    } while (h > 0);
  }
}

void av1_convolve_2d_scale_neon_i8mm(const uint8_t *src, int src_stride,
                                     uint8_t *dst, int dst_stride, int w, int h,
                                     const InterpFilterParams *filter_params_x,
                                     const InterpFilterParams *filter_params_y,
                                     const int subpel_x_qn, const int x_step_qn,
                                     const int subpel_y_qn, const int y_step_qn,
                                     ConvolveParams *conv_params) {
  if (w < 4 || h < 4) {
    av1_convolve_2d_scale_c(src, src_stride, dst, dst_stride, w, h,
                            filter_params_x, filter_params_y, subpel_x_qn,
                            x_step_qn, subpel_y_qn, y_step_qn, conv_params);
    return;
  }

  // For the interpolation 8-tap filters are used.
  assert(filter_params_y->taps <= 8 && filter_params_x->taps <= 8);

  DECLARE_ALIGNED(32, int16_t,
                  im_block[(2 * MAX_SB_SIZE + MAX_FILTER_TAP) * MAX_SB_SIZE]);
  int im_h = (((h - 1) * y_step_qn + subpel_y_qn) >> SCALE_SUBPEL_BITS) +
             filter_params_y->taps;
  int im_stride = MAX_SB_SIZE;
  CONV_BUF_TYPE *dst16 = conv_params->dst;
  const int dst16_stride = conv_params->dst_stride;

  // Account for needing filter_taps / 2 - 1 lines prior and filter_taps / 2
  // lines post both horizontally and vertically.
  const ptrdiff_t horiz_offset = filter_params_x->taps / 2 - 1;
  const ptrdiff_t vert_offset = (filter_params_y->taps / 2 - 1) * src_stride;

  // Horizontal filter
  convolve_horiz_scale_neon_i8mm(
      src - horiz_offset - vert_offset, src_stride, im_block, im_stride, w,
      im_h, filter_params_x->filter_ptr, subpel_x_qn, x_step_qn);

  // Vertical filter
  if (UNLIKELY(conv_params->is_compound)) {
    if (conv_params->do_average) {
      if (conv_params->use_dist_wtd_comp_avg) {
        compound_dist_wtd_convolve_vert_scale_neon(
            im_block, im_stride, dst, dst_stride, dst16, dst16_stride, w, h,
            filter_params_y->filter_ptr, conv_params, subpel_y_qn, y_step_qn);
      } else {
        compound_avg_convolve_vert_scale_neon(
            im_block, im_stride, dst, dst_stride, dst16, dst16_stride, w, h,
            filter_params_y->filter_ptr, subpel_y_qn, y_step_qn);
      }
    } else {
      compound_convolve_vert_scale_neon(
          im_block, im_stride, dst16, dst16_stride, w, h,
          filter_params_y->filter_ptr, subpel_y_qn, y_step_qn);
    }
  } else {
    convolve_vert_scale_neon(im_block, im_stride, dst, dst_stride, w, h,
                             filter_params_y->filter_ptr, subpel_y_qn,
                             y_step_qn);
  }
}
