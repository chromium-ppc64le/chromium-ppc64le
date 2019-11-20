# Copyright 2019 Colin Samples
#
# SPDX-License-Identifier: Apache-2.0
#

.DEFAULT_GOAL := all

NUM_THREADS ?= 16
CONCURRENT_LINKS ?= 2

include common.mk

gn_url := https://gn.googlesource.com/gn
llvm_url := https://github.com/llvm/llvm-project/archive/$(llvm_rev).tar.gz
chrome_url := https://commondatastorage.googleapis.com/chromium-browser-official/chromium-$(chrome_ver).tar.xz

# Quilt series files to apply to chrome
ifdef UNGOOGLED
chrome-series := \
    patches/chrome/chromium-ppc64le-patches-quilt/patches/series \
    patches/chrome/series.ungoogled \
    patches/chrome/series.extra
else
chrome-series := \
    patches/chrome/chromium-ppc64le-patches-quilt/patches/series \
    patches/chrome/series.extra
endif

###############################################################################
# Targets
###############################################################################
gn-bin-dir := $(CURDIR)/gn/out
gn-exe := $(gn-bin-dir)/gn

llvm-archive := $(llvm_rev).tar.gz
llvm-dir := $(CURDIR)/llvm-project-$(llvm_rev)
llvm-build-dir := $(CURDIR)/llvm-build
llvm-patch-series-dir := $(CURDIR)/patches/llvm
clang := $(llvm-build-dir)/bin/clang

chrome-archive := chromium-$(chrome_ver).tar.xz
chrome-dir := $(CURDIR)/chromium-$(chrome_ver)
chrome-target := out/Release
chrome-target-dir := $(chrome-dir)/$(chrome-target)
chrome-args-gn := $(chrome-target-dir)/args.gn
chrome-rpm-file := $(chrome-target-dir)/$(chrome-rpm-file-name)
chrome-dist-file := $(chrome-target-dir)/$(chrome-dist-file-name)

chrome-args-gn-in := conf/args.gn.in
ifdef UNGOOGLED
ug-chrome-args-gn-extra := conf/ungoogled_extra.gn
endif

chrome := $(chrome-target-dir)/chrome

ug-chrome-patches-dir := $(CURDIR)/patches/chrome/ungoogled-chromium

llvm-patched := llvm-patched.stamp
libdav1d-rebuilt := libdav1d-rebuilt.stamp
ffmpeg-rebuilt := ffmpeg-rebuilt.stamp
libvpx-rebuilt := libvpx-rebuilt.stamp
chrome-ppc-patched := chrome-ppc-patched.stamp
chrome-patched := chrome-patched.stamp
chrome-configured := chrome-configured.stamp
ifdef UNGOOGLED
ug-chrome-pruned := ug-chrome-pruned.stamp
ug-chrome-domain-subbed := ug-chrome-domain-subbed.stamp
ug-chrome-extra-args-applied := ug-chrome-extra-args-applied.stamp
endif

media-rebuild-prereqs := $(clang) $(chrome-patched) $(ug-chrome-domain-subbed)

###############################################################################
# Environment
###############################################################################
ORIG_CC := $(CC)
ORIG_CXX := $(CXX)
ORIG_AR := $(AR)
ORIG_NM := $(NM)

# Use the compiled version of clang once it's built
export CC = $(or $(realpath $(clang)), $(ORIG_CC))
export CXX = $(or $(realpath $(llvm-build-dir)/bin/clang++), $(ORIG_CXX))
export AR = $(or $(realpath $(llvm-build-dir)/bin/llvm-ar), $(ORIG_AR))
export NM = $(or $(realpath $(llvm-build-dir)/bin/llvm-nm), $(ORIG_NM))

ignored_warnings := -Wno-shorten-64-to-32 \
		    -Wno-deprecated-declarations \
		    -Wno-deprecated \
		    -Wno-unused-function \
		    -Wno-unused-variable \
		    -Wno-implicit-float-conversion \
		    -Wno-unused-private-field
opt_flags := -mcpu=power9 -mtune=power9

export CFLAGS ?= $(ignored_warnings) $(opt_flags)
export CXXFLAGS ?= $(ignored_warnings) $(opt_flags)
export LDFLAGS += -lm

ORIG_PATH := $(PATH)
export PATH := $(gn-bin-dir):$(llvm-build-dir)/bin:$(ORIG_PATH)

###############################################################################
# Rules
###############################################################################
$(artifact-dir):
	mkdir -p $@

gn:
	git clone $(gn_url)

$(gn-exe): | gn
	cd gn && \
	env CC=/usr/bin/clang \
	    CXX=/usr/bin/clang++ \
	    AR=/usr/bin/ar \
	    python build/gen.py && \
	ninja -j $(NUM_THREADS) -C out

###############################################################################
# LLVM
###############################################################################
$(llvm-archive):
	wget -q $(llvm_url)

$(llvm-dir): | $(llvm-archive)
	tar xzf $|

$(llvm-patched): export QUILT_PATCHES := $(llvm-patch-series-dir)
$(llvm-patched): | $(llvm-dir)
	cd $| && quilt push -a
	touch $@

$(llvm-build-dir):
	mkdir -p $@

$(llvm-build-dir)/CMakeCache.txt: $(llvm-patched) | $(llvm-build-dir) $(llvm-dir)
	cmake -S $(llvm-dir)/llvm -B $(llvm-build-dir) \
	    -G "Ninja" \
	    -DCMAKE_BUILD_TYPE=Release \
	    -DCMAKE_INSTALL_PREFIX=$(artifact-dir)/$(llvm-dist-dir) \
	    -DLLVM_ENABLE_PROJECTS="clang;lld" \
	    -DLLVM_TARGETS_TO_BUILD="PowerPC" \
	    -DCMAKE_AR=/usr/bin/ar \
	    -DCMAKE_C_COMPILER=/usr/bin/clang \
	    -DCMAKE_CXX_COMPILER=/usr/bin/clang++

$(clang): $(llvm-build-dir)/CMakeCache.txt
	ninja -C $(llvm-build-dir) -j $(NUM_THREADS)

$(llvm-dist-artifact): $(clang) | $(artifact-dir)
	ninja -C $(llvm-build-dir) install
	tar cJf $@ $|/$(llvm-dist-dir)

###############################################################################
# Chrome
###############################################################################
$(chrome-archive):
	wget -q $(chrome_url)

$(chrome-dir): | $(chrome-archive)
	tar xf $|

$(chrome-target-dir): | $(chrome-dir)
	mkdir -p $@

# This regex takes concatenates the lists of patches from series files in
# $(chrome-series) and appends the relevant directory to each patch, ignoring
# comments and empty lines.
series: $(chrome-series)
	$(foreach series,$^,\
	    sed -e 's|^\([^#]\+\)$$|$(dir $(series))\1|' $(series) >> $@ &&) :

$(chrome-patched): export QUILT_PATCHES := $(CURDIR)
$(chrome-patched): series $(ug-chrome-pruned) | $(chrome-dir)
	cd $| && quilt push -a
	touch $@

ifdef UNGOOGLED
$(ug-chrome-pruned): | $(chrome-dir)
	$(ug-chrome-patches-dir)/utils/prune_binaries.py $| \
	    $(ug-chrome-patches-dir)/pruning.list
	touch $@

$(ug-chrome-domain-subbed): $(chrome-patched) | $(chrome-dir)
	rm -f domsubcache.tar.gz
	$(ug-chrome-patches-dir)/utils/domain_substitution.py apply \
	    -r $(ug-chrome-patches-dir)/domain_regex.list \
	    -f $(ug-chrome-patches-dir)/domain_substitution.list \
	    -c domsubcache.tar.gz \
	    $|
	touch $@
endif

$(chrome-args-gn): $(chrome-args-gn-in) \
		   $(ug-chrome-args-gn-extra) \
		   | $(chrome-target-dir)
	sed -e 's|@@CLANG_BASE_PATH@@|$(llvm-build-dir)|g' \
	    -e 's|@@CONCURRENT_LINKS@@|$(CONCURRENT_LINKS)|g' \
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

$(chrome-configured): $(chrome-args-gn) \
                      $(ffmpeg-rebuilt) \
		      $(libvpx-rebuilt) \
		      | $(gn-exe)
	gn gen --root=$(chrome-dir) $(chrome-target-dir)
	touch $@

$(chrome): $(chrome-configured)
	ninja -C $(chrome-target-dir) -j $(NUM_THREADS) \
	    media chrome chrome_sandbox chromedriver clear_key_cdm

$(chrome-rpm-file): $(chrome)
	ninja -C $(chrome-target-dir) -j $(NUM_THREADS) $(chrome_channel)_rpm

# For the tarball artifact, just extract the files from the RPM, since it only
# includes the files needed and the binaries are already stripped
$(chrome-dist-file): $(chrome-rpm-file)
	rpm2cpio $< | cpio -dium
	mv opt/chromium.org/chromium $(chrome-file-name-base)
	tar cJf $@ $(chrome-file-name-base)

$(chrome-rpm-artifact): $(chrome-rpm-file) $(chrome-dist-file) | $(artifact-dir)
	mv $< $@

$(chrome-dist-artifact): $(chrome-dist-file) | $(artifact-dir)
	mv $< $@

.PHONY: clean-chrome
clean-chrome:
	rm -rf $(chrome-dir)
	rm -f series \
	      $(chrome-patched) \
	      $(ug-chrome-pruned) \
	      domsubcache.tar.gz \
	      $(ug-chrome-domain-subbed) \
	      $(chrome-args-gn) \
	      $(libdav1d-rebuilt) \
	      $(ffmpeg-rebuilt) \
	      $(libvpx-rebuilt) \
	      $(chrome-configured)

.PHONY: retouch-chrome-prereqs
retouch-chrome-prereqs:
	touch $(chrome-patched) \
	      $(ug-chrome-pruned) \
	      $(ug-chrome-domain-subbed) \
	      $(chrome-args-gn) \
	      $(libdav1d-rebuilt) \
	      $(ffmpeg-rebuilt) \
	      $(libvpx-rebuilt)

.PHONY: llvm
llvm: $(clang)

.PHONY: rpm
rpm: $(chrome-rpm-artifact)

.PHONY: dist
dist: $(chrome-dist-artifact)

.PHONY: llvm-dist
llvm-dist: $(llvm-dist-artifact)

.PHONY: all
all: rpm dist

