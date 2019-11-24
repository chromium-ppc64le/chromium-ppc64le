# Copyright 2019 Colin Samples
#
# SPDX-License-Identifier: Apache-2.0
#

.DEFAULT_GOAL := all

include common.mk

###############################################################################
# Patches
###############################################################################
ifdef UNGOOGLED
patch-series := \
    patches/chrome/chromium-ppc64le-patches-quilt/patches/series \
    patches/chrome/series.ungoogled \
    patches/chrome/series.extra
else
patch-series := \
    patches/chrome/chromium-ppc64le-patches-quilt/patches/series \
    patches/chrome/series.extra
endif

###############################################################################
# Environment
###############################################################################
export CC := $(realpath $(llvm-dir)/bin/clang)
export CXX := $(realpath $(llvm-dir)/bin/clang++)
export AR := $(realpath $(llvm-dir)/bin/llvm-ar)
export NM := $(realpath $(llvm-dir)/bin/llvm-nm)

ORIG_PATH := $(PATH)
export PATH := $(gn-bin-dir):$(llvm-dir)/bin:$(ORIG_PATH)

export CCACHE_BASEDIR := $(CURDIR)
export CCACHE_DIR := $(CURDIR)/.ccache

###############################################################################
# Targets
###############################################################################
target := out/Release
target-dir := $(chrome-dir)/$(target)
args-gn := $(target-dir)/args.gn
rpm-file := $(target-dir)/$(chrome-rpm-file-name)
dist-file := $(target-dir)/$(chrome-dist-file-name)

args-gn-in := conf/args.gn.in
ifdef UNGOOGLED
ug-args-gn-extra := conf/ungoogled_extra.gn
endif

chrome := $(target-dir)/chrome

ug-chrome-patches-dir := $(CURDIR)/patches/chrome/ungoogled-chromium

libdav1d-rebuilt := $(dist-prefix)libdav1d-rebuilt.stamp
ffmpeg-rebuilt := $(dist-prefix)ffmpeg-rebuilt.stamp
libvpx-rebuilt := $(dist-prefix)libvpx-rebuilt.stamp
patched := $(dist-prefix)patched.stamp
configured := $(dist-prefix)configured.stamp
ifdef UNGOOGLED
ug-chrome-pruned := ug-chrome-pruned.stamp
ug-chrome-domain-subbed := ug-chrome-domain-subbed.stamp
ug-chrome-extra-args-applied := ug-chrome-extra-args-applied.stamp
endif

media-rebuild-prereqs := $(clang) $(patched) $(ug-chrome-domain-subbed)

###############################################################################
# Rules
###############################################################################
$(artifact-dir):
	mkdir -p $@

$(target-dir): | $(chrome-dir)
	mkdir -p $@

# This regex takes concatenates the lists of patches from series files in
# $(patch-series) and appends the relevant directory to each patch, ignoring
# comments and empty lines.
series: $(patch-series)
	$(foreach series,$^,\
	    sed -e 's|^\([^#]\+\)$$|$(dir $(series))\1|' $(series) >> $@ &&) :

$(patched): export QUILT_PATCHES := $(CURDIR)
$(patched): series $(ug-chrome-pruned) | $(chrome-dir)
	cd $| && quilt push -a
	touch $@

ifdef UNGOOGLED
$(ug-chrome-pruned): | $(chrome-dir)
	$(ug-chrome-patches-dir)/utils/prune_binaries.py $| \
	    $(ug-chrome-patches-dir)/pruning.list
	touch $@

$(ug-chrome-domain-subbed): $(patched) | $(chrome-dir)
	rm -f domsubcache.tar.gz
	$(ug-chrome-patches-dir)/utils/domain_substitution.py apply \
	    -r $(ug-chrome-patches-dir)/domain_regex.list \
	    -f $(ug-chrome-patches-dir)/domain_substitution.list \
	    -c domsubcache.tar.gz \
	    $|
	touch $@
endif

$(args-gn): $(args-gn-in) $(ug-args-gn-extra) | $(target-dir)
	sed -e 's|@@CLANG_BASE_PATH@@|$(llvm-dir)|g' \
	    -e 's|@@CONCURRENT_LINKS@@|$(CONCURRENT_LINKS)|g' \
	    -e 's|@@USE_LTO@@|$(USE_LTO)|g' \
	    $^ > $@

# This is not used currently, but should work with chrome 79
$(libdav1d-rebuilt): $(media-rebuild-prereqs) | $(chrome-dir)
	+cd $|/third_party/dav1d && \
	./generate_configs.py && \
	./generate_source.py
	touch $@

$(ffmpeg-rebuilt): $(media-rebuild-prereqs) | $(chrome-dir)
	+cd $|/third_party/ffmpeg && \
	./chromium/scripts/build_ffmpeg.py --branding="ChromeOS" linux ppc64 && \
	./chromium/scripts/generate_gn.py && \
	./chromium/scripts/copy_config.sh
	touch $@

$(libvpx-rebuilt): $(media-rebuild-prereqs) $(gn-exe) | $(chrome-dir)
	+cd $|/third_party/libvpx && \
	mkdir -p source/config/linux/ppc64 && \
	./generate_gni.sh
	touch $@

$(configured): $(args-gn) \
               $(ffmpeg-rebuilt) \
	           $(libvpx-rebuilt) \
	           | $(gn-exe)
	gn gen --root=$(chrome-dir) $(target-dir)
	touch $@

$(chrome): $(configured)
	ninja -C $(target-dir) -j $(NUM_THREADS) \
	    media chrome chrome_sandbox chromedriver clear_key_cdm

$(rpm-file): $(chrome)
	ninja -C $(target-dir) -j $(NUM_THREADS) $(chrome_channel)_rpm

# For the tarball artifact, just extract the files from the RPM, since it only
# includes the files needed and the binaries are already stripped
$(dist-file): $(rpm-file)
	rpm2cpio $< | cpio -dium
	mv opt/chromium.org/chromium $(chrome-file-name-base)
	tar cJf $@ $(chrome-file-name-base)

$(chrome-rpm-artifact): $(rpm-file) $(dist-file) | $(artifact-dir)
	mv $< $@

$(chrome-dist-artifact): $(dist-file) | $(artifact-dir)
	mv $< $@

.PHONY: clean-patches
clean-patches: export QUILT_PATCHES := $(CURDIR)
clean-patches: | $(chrome-dir)
	cd $| && quilt pop -af
	rm -f series
	rm -rf $|/.pc

.PHONY: clean-config
clean-config:
	rm -f $(args-gn)

.PHONY: clean-chrome
clean-chrome:
	rm -rf $(chrome-dir)
	rm -f series \
	      $(patched) \
	      $(ug-chrome-pruned) \
	      domsubcache.tar.gz \
	      $(ug-chrome-domain-subbed) \
	      $(args-gn) \
	      $(libdav1d-rebuilt) \
	      $(ffmpeg-rebuilt) \
	      $(libvpx-rebuilt) \
	      $(configured)

.PHONY: retouch-chrome-prereqs
retouch-chrome-prereqs:
	touch $(patched) \
	      $(ug-chrome-pruned) \
	      $(ug-chrome-domain-subbed) \
	      $(args-gn) \
	      $(libdav1d-rebuilt) \
	      $(ffmpeg-rebuilt) \
          $(libvpx-rebuilt)

.PHONY: rpm
rpm: $(chrome-rpm-artifact)

.PHONY: dist
dist: $(chrome-dist-artifact)

.PHONY: all
all: rpm dist

