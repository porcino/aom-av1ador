##
##  Copyright (c) 2010 The WebM project authors. All Rights Reserved.
##
##  Use of this source code is governed by a BSD-style license
##  that can be found in the LICENSE file in the root of the source
##  tree. An additional intellectual property rights grant can be found
##  in the file PATENTS.  All contributing project authors may
##  be found in the AUTHORS file in the root of the source tree.
##


# List of examples to build. UTILS are files that are taken from the source
# tree directly, and GEN_EXAMPLES are files that are created from the
# examples folder.
UTILS-$(CONFIG_DECODERS)    += ivfdec.c
ivfdec.SRCS                 += md5_utils.c md5_utils.h
ivfdec.SRCS                 += vpx_ports/vpx_timer.h
ivfdec.SRCS                 += vpx/vpx_integer.h
ivfdec.SRCS                 += args.c args.h vpx_ports/config.h
ivfdec.SRCS                 += nestegg/halloc/halloc.h
ivfdec.SRCS                 += nestegg/halloc/src/align.h
ivfdec.SRCS                 += nestegg/halloc/src/halloc.c
ivfdec.SRCS                 += nestegg/halloc/src/hlist.h
ivfdec.SRCS                 += nestegg/halloc/src/macros.h
ivfdec.SRCS                 += nestegg/include/nestegg/nestegg.h
ivfdec.SRCS                 += nestegg/src/nestegg.c
ivfdec.GUID                  = BA5FE66F-38DD-E034-F542-B1578C5FB950
ivfdec.DESCRIPTION           = Full featured decoder
UTILS-$(CONFIG_ENCODERS)    += ivfenc.c
ivfenc.SRCS                 += args.c args.h y4minput.c y4minput.h
ivfenc.SRCS                 += vpx_ports/config.h vpx_ports/mem_ops.h
ivfenc.SRCS                 += vpx_ports/mem_ops_aligned.h
ivfenc.SRCS                 += libmkv/EbmlIDs.h
ivfenc.SRCS                 += libmkv/EbmlWriter.c
ivfenc.SRCS                 += libmkv/EbmlWriter.h
ivfenc.GUID                  = 548DEC74-7A15-4B2B-AFC3-AA102E7C25C1
ivfenc.DESCRIPTION           = Full featured encoder

# XMA example disabled for now, not used in VP8
#UTILS-$(CONFIG_DECODERS)    += example_xma.c
#example_xma.GUID             = A955FC4A-73F1-44F7-135E-30D84D32F022
#example_xma.DESCRIPTION      = External Memory Allocation mode usage

GEN_EXAMPLES-$(CONFIG_DECODERS) += simple_decoder.c
simple_decoder.GUID              = D3BBF1E9-2427-450D-BBFF-B2843C1D44CC
simple_decoder.DESCRIPTION       = Simplified decoder loop
GEN_EXAMPLES-$(CONFIG_DECODERS) += postproc.c
postproc.GUID                    = 65E33355-F35E-4088-884D-3FD4905881D7
postproc.DESCRIPTION             = Decoder postprocessor control
GEN_EXAMPLES-$(CONFIG_DECODERS) += decode_to_md5.c
decode_to_md5.SRCS              += md5_utils.h md5_utils.c
decode_to_md5.GUID               = 59120B9B-2735-4BFE-B022-146CA340FE42
decode_to_md5.DESCRIPTION        = Frame by frame MD5 checksum

GEN_EXAMPLES-$(CONFIG_ENCODERS) += simple_encoder.c
simple_encoder.GUID              = 4607D299-8A71-4D2C-9B1D-071899B6FBFD
simple_encoder.DESCRIPTION       = Simplified encoder loop
GEN_EXAMPLES-$(CONFIG_ENCODERS) += twopass_encoder.c
twopass_encoder.GUID             = 73494FA6-4AF9-4763-8FBB-265C92402FD8
twopass_encoder.DESCRIPTION      = Two-pass encoder loop
GEN_EXAMPLES-$(CONFIG_ENCODERS) += force_keyframe.c
force_keyframe.GUID              = 3C67CADF-029F-4C86-81F5-D6D4F51177F0
force_keyframe.DESCRIPTION       = Force generation of keyframes
ifeq ($(CONFIG_DECODERS),yes)
GEN_EXAMPLES-$(CONFIG_ENCODERS) += decode_with_drops.c
endif
decode_with_drops.GUID           = CE5C53C4-8DDA-438A-86ED-0DDD3CDB8D26
decode_with_drops.DESCRIPTION    = Drops frames while decoding
GEN_EXAMPLES-$(CONFIG_ENCODERS) += error_resilient.c
error_resilient.GUID             = DF5837B9-4145-4F92-A031-44E4F832E00C
error_resilient.DESCRIPTION      = Error Resiliency Feature

GEN_EXAMPLES-$(CONFIG_VP8_ENCODER) += vp8_scalable_patterns.c
vp8_scalable_patterns.GUID          = 0D6A210B-F482-4D6F-8570-4A9C01ACC88C
vp8_scalable_patterns.DESCRIPTION   = VP8 Scalable Bitstream Patterns
GEN_EXAMPLES-$(CONFIG_VP8_ENCODER) += vp8_set_maps.c
vp8_set_maps.GUID                   = ECB2D24D-98B8-4015-A465-A4AF3DCC145F
vp8_set_maps.DESCRIPTION            = VP8 set active and ROI maps
GEN_EXAMPLES-$(CONFIG_VP8_ENCODER) += vp8cx_set_ref.c
vp8cx_set_ref.GUID                  = C5E31F7F-96F6-48BD-BD3E-10EBF6E8057A
vp8cx_set_ref.DESCRIPTION           = VP8 set encoder reference frame


# Handle extra library flags depending on codec configuration
CODEC_EXTRA_LIBS-$(CONFIG_VP8)         += m

#
# End of specified files. The rest of the build rules should happen
# automagically from here.
#


# Examples need different flags based on whether we're building
# from an installed tree or a version controlled tree. Determine
# the proper paths.
ifeq ($(HAVE_ALT_TREE_LAYOUT),yes)
    LIB_PATH := $(SRC_PATH_BARE)/../lib
    INC_PATH := $(SRC_PATH_BARE)/../include
else
    LIB_PATH-yes                     += $(if $(BUILD_PFX),$(BUILD_PFX),.)
    INC_PATH-$(CONFIG_VP8_DECODER)   += $(SRC_PATH_BARE)/vp8
    INC_PATH-$(CONFIG_VP8_ENCODER)   += $(SRC_PATH_BARE)/vp8
    LIB_PATH := $(call enabled,LIB_PATH)
    INC_PATH := $(call enabled,INC_PATH)
endif
CFLAGS += $(addprefix -I,$(INC_PATH))
LDFLAGS += $(addprefix -L,$(LIB_PATH))


# Expand list of selected examples to build (as specified above)
UTILS           = $(call enabled,UTILS)
GEN_EXAMPLES    = $(call enabled,GEN_EXAMPLES)
ALL_EXAMPLES    = $(UTILS) $(GEN_EXAMPLES)
UTIL_SRCS       = $(foreach ex,$(UTILS),$($(ex:.c=).SRCS))
ALL_SRCS        = $(foreach ex,$(ALL_EXAMPLES),$($(ex:.c=).SRCS))
CODEC_EXTRA_LIBS=$(sort $(call enabled,CODEC_EXTRA_LIBS))


# Expand all example sources into a variable containing all sources
# for that example (not just them main one specified in UTILS/GEN_EXAMPLES)
# and add this file to the list (for MSVS workspace generation)
$(foreach ex,$(ALL_EXAMPLES),$(eval $(ex:.c=).SRCS += $(ex) examples.mk))


# If this is a universal (fat) binary, then all the subarchitectures have
# already been built and our job is to stitch them together. The
# BUILD_OBJS variable indicates whether we should be building
# (compiling, linking) the library. The LIPO_OBJS variable indicates
# that we're stitching.
$(eval $(if $(filter universal%,$(TOOLCHAIN)),LIPO_OBJS,BUILD_OBJS):=yes)


# Create build/install dependencies for all examples. The common case
# is handled here. The MSVS case is handled below.
NOT_MSVS = $(if $(CONFIG_MSVS),,yes)
DIST-BINS-$(NOT_MSVS)      += $(addprefix bin/,$(ALL_EXAMPLES:.c=))
INSTALL-BINS-$(NOT_MSVS)   += $(addprefix bin/,$(UTILS:.c=))
DIST-SRCS-yes              += $(ALL_SRCS)
INSTALL-SRCS-yes           += $(UTIL_SRCS)
OBJS-$(NOT_MSVS)           += $(if $(BUILD_OBJS),$(call objs,$(ALL_SRCS)))
BINS-$(NOT_MSVS)           += $(addprefix $(BUILD_PFX),$(ALL_EXAMPLES:.c=))


# Instantiate linker template for all examples.
CODEC_LIB=$(if $(CONFIG_DEBUG_LIBS),vpx_g,vpx)
$(foreach bin,$(BINS-yes),\
    $(if $(BUILD_OBJS),$(eval $(bin): $(LIB_PATH)/lib$(CODEC_LIB).a))\
    $(if $(BUILD_OBJS),$(eval $(call linker_template,$(bin),\
        $(call objs,$($(notdir $(bin)).SRCS)) \
        -l$(CODEC_LIB) $(addprefix -l,$(CODEC_EXTRA_LIBS))\
        )))\
    $(if $(LIPO_OBJS),$(eval $(call lipo_bin_template,$(bin))))\
    )


# Rules to generate the GEN_EXAMPLES sources
.PRECIOUS: %.c
CLEAN-OBJS += $(GEN_EXAMPLES)
%.c: examples/%.txt
	@echo "    [EXAMPLE] $@"
	@$(SRC_PATH_BARE)/examples/gen_example_code.sh $< > $@


# The following pairs define a mapping of locations in the distribution
# tree to locations in the source/build trees.
INSTALL_MAPS += src/%.c   %.c
INSTALL_MAPS += src/%     $(SRC_PATH_BARE)/%
INSTALL_MAPS += bin/%     %
INSTALL_MAPS += %         %


# Set up additional MSVS environment
ifeq ($(CONFIG_MSVS),yes)
CODEC_LIB=$(if $(CONFIG_STATIC_MSVCRT),vpxmt,vpxmd)
# This variable uses deferred expansion intentionally, since the results of
# $(wildcard) may change during the course of the Make.
VS_PLATFORMS = $(foreach d,$(wildcard */Release/$(CODEC_LIB).lib),$(word 1,$(subst /, ,$(d))))
INSTALL_MAPS += $(foreach p,$(VS_PLATFORMS),bin/$(p)/%  $(p)/Release/%)
endif

# Build Visual Studio Projects. We use a template here to instantiate
# explicit rules rather than using an implicit rule because we want to
# leverage make's VPATH searching rather than specifying the paths on
# each file in ALL_EXAMPLES. This has the unfortunate side effect that
# touching the source files trigger a rebuild of the project files
# even though there is no real dependency there (the dependency is on
# the makefiles). We may want to revisit this.
define vcproj_template
$(1): $($(1:.vcproj=).SRCS)
	@echo "    [vcproj] $$@"
	$$(SRC_PATH_BARE)/build/make/gen_msvs_proj.sh\
            --exe\
            --target=$$(TOOLCHAIN)\
            --name=$$(@:.vcproj=)\
            --ver=$$(CONFIG_VS_VERSION)\
            --proj-guid=$$($$(@:.vcproj=).GUID)\
            $$(if $$(CONFIG_STATIC_MSVCRT),--static-crt) \
            --out=$$@ $$(CFLAGS) $$(LDFLAGS) -l$$(CODEC_LIB) -lwinmm $$^
endef
PROJECTS-$(CONFIG_MSVS) += $(ALL_EXAMPLES:.c=.vcproj)
INSTALL-BINS-$(CONFIG_MSVS) += $(foreach p,$(VS_PLATFORMS),\
                               $(addprefix bin/$(p)/,$(ALL_EXAMPLES:.c=.exe)))
$(foreach proj,$(call enabled,PROJECTS),\
    $(eval $(call vcproj_template,$(proj))))



#
# Documentation Rules
#
%.dox: examples/%.txt
	@echo "    [DOXY] $@"
	@$(SRC_PATH_BARE)/examples/gen_example_text.sh $< | \
         $(SRC_PATH_BARE)/examples/gen_example_doxy.php \
             example_$(@:.dox=)  $(@:.dox=.c) > $@

%.dox: %.c
	@echo "    [DOXY] $@"
	@echo "/*!\page example_$(@:.dox=) $(@:.dox=)" > $@
	@echo "   \includelineno $(notdir $<)" >> $@
	@echo "*/" >> $@

samples.dox: examples.mk
	@echo "    [DOXY] $@"
	@echo "/*!\page samples Sample Code" > $@
	@echo "    This SDK includes a number of sample applications."\
	      "each sample documents a feature of the SDK in both prose"\
	      "and the associated C code. In general, later samples"\
	      "build upon prior samples, so it is best to work through the"\
	      "list in order. The following samples are included: ">>$@
	@$(foreach ex,$(GEN_EXAMPLES:.c=),\
	   echo "     - \subpage example_$(ex) $($(ex).DESCRIPTION)" >> $@;)
	@echo >> $@
	@echo "    In addition, the SDK contains a number of utilities."\
              "Since these utilities are built upon the concepts described"\
              "in the sample code listed above, they are not documented in"\
              "pieces like the samples are. Thir sourcre is included here"\
              "for reference. The following utilities are included:" >> $@
	@$(foreach ex,$(UTILS:.c=),\
	   echo "     - \subpage example_$(ex) $($(ex).DESCRIPTION)" >> $@;)
	@echo "*/" >> $@

CLEAN-OBJS += examples.doxy samples.dox $(ALL_EXAMPLES:.c=.dox)
DOCS-yes += examples.doxy samples.dox $(ALL_EXAMPLES:.c=.dox)
examples.doxy: samples.dox $(ALL_EXAMPLES:.c=.dox)
	@echo "INPUT += $^" > $@
