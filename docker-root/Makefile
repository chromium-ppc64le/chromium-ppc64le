# Copyright 2019 Colin Samples
#
# SPDX-License-Identifier: Apache-2.0
#

.DEFAULT_GOAL := all

num_threads := 16

include common.mk

gn_url := https://gn.googlesource.com/gn
llvm_url := https://github.com/llvm/llvm-project/archive/$(llvm_rev).tar.gz
chrome_url := https://commondatastorage.googleapis.com/chromium-browser-official/chromium-$(chrome_ver).tar.xz

# Targets
gn-bin-dir := $(CURDIR)/gn/out
gn-exe := $(gn-bin-dir)/gn

llvm-archive := $(llvm_rev).tar.gz
llvm-dir := $(CURDIR)/llvm-project-$(llvm_rev)
llvm-build-dir := $(CURDIR)/llvm-build
llvm-patches-dir := $(CURDIR)/patches/llvm
clang := $(llvm-build-dir)/bin/clang

# from chrome 79 beta DEPS
dav1d-archive := 62fcd0cb19d2fe46af7541d8185de86d45d58697.tar.gz
dav1d_url := https://chromium.googlesource.com/external/github.com/videolan/dav1d/+archive/62fcd0cb19d2fe46af7541d8185de86d45d58697.tar.gz

chrome-patches-dir := $(CURDIR)/patches/chrome
chrome-ppc-patches-dir := $(chrome-patches-dir)/chromium-ppc64le-patches-quilt/patches
chrome-archive := chromium-$(chrome_ver).tar.xz
chrome-dir := $(CURDIR)/chromium-$(chrome_ver)
chrome-target := out/Release
chrome-target-dir := $(chrome-dir)/$(chrome-target)
chrome-args-gn := $(chrome-target-dir)/args.gn
chrome-rpm-file := $(chrome-target-dir)/$(chrome-rpm-file-name)
chrome-dist-file := $(chrome-target-dir)/$(chrome-dist-file-name)

chrome := $(chrome-target-dir)/chrome

llvm-patched := llvm-patched.stamp
libdav1d-rebuilt := libdav1d-rebuilt.stamp
ffmpeg-rebuilt := ffmpeg-rebuilt.stamp
libvpx-rebuilt := libvpx-rebuilt.stamp
chrome-ppc-patched := chrome-ppc-patched.stamp
chrome-patched := chrome-patched.stamp
chrome-configured := chrome-configured.stamp

# Enviroment
ORIG_CC := $(CC)
ORIG_CXX := $(CXX)
ORIG_AR := $(AR)
ORIG_NM := $(NM)

# Use the compiled verion of clang once it's built
export CC = $(or $(realpath $(clang)), $(ORIG_CC))
export CXX = $(or $(realpath $(llvm-build-dir)/bin/clang++), $(ORIG_CXX))
export AR = $(or $(realpath $(llvm-build-dir)/bin/llvm-ar), $(ORIG_AR))
export NM = $(or $(realpath $(llvm-build-dir)/bin/llvm-nm), $(ORIG_NM))

ignored_warnings := -Wno-shorten-64-to-32 \
		    -Wno-deprecated-declarations \
		    -Wno-deprecated
opt_flags := -mcpu=power9 -mtune=power9

export CFLAGS ?= $(ignored_warnings) $(opt_flags)
export CXXFLAGS ?= $(ignored_warnings) $(opt_flags)
export LDFLAGS += -lm

ORIG_PATH := $(PATH)
export PATH := $(gn-bin-dir):$(llvm-build-dir)/bin:$(ORIG_PATH)

# apply-patch-series -- function to apply a patch series using quilt
# usage: $(call apply-patch-series,<patch series dir>,<dir to apply patches>)
define apply-patch-series
cd $(2) && env QUILT_PATCHES="$(1)" quilt push -a
rm -rf $(2)/.pc
endef


$(artifact-dir):
	mkdir -p $@

gn:
	git clone $(gn_url)

$(gn-exe): | gn
	cd gn && \
	env CC=$(ORIG_CC) CXX=$(ORIG_CXX) AR=$(ORIG_AR) python build/gen.py && \
	ninja -j $(num_threads) -C out

$(llvm-archive):
	wget -q $(llvm_url)

$(llvm-dir): | $(llvm-archive)
	tar xzf $|

$(llvm-patched): $(llvm-patches-dir) | $(llvm-dir)
	$(call apply-patch-series,$<,$|)
	touch $@

$(llvm-build-dir): $(llvm-patched)
	mkdir -p $@

$(llvm-build-dir)/CMakeCache.txt: | $(llvm-build-dir) $(llvm-dir)
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
	ninja -C $(llvm-build-dir) -j $(num_threads)

$(llvm-dist-artifact): $(clang) | $(artifact-dir)
	ninja -C $(llvm-build-dir) install
	tar cJf $@ $|/$(llvm-dist-dir)

$(chrome-archive):
	wget -q $(chrome_url)

$(chrome-dir): | $(chrome-archive)
	tar xf $|

$(chrome-target-dir): | $(chrome-dir)
	mkdir -p $@

$(chrome-ppc-patched): $(chrome-ppc-patches-dir) | $(chrome-dir)
	rm -rf $(chrome-dir)/third_party/dav1d/libdav1d/*
	cd $(chrome-dir)/third_party/dav1d/libdav1d && wget -q $(dav1d_url)
	cd $(chrome-dir)/third_party/dav1d/libdav1d && tar xf $(dav1d-archive)
	$(call apply-patch-series,$<,$|)
	touch $@

$(chrome-patched): $(chrome-patches-dir) $(chrome-ppc-patched) | $(chrome-dir)
	$(call apply-patch-series,$<,$|)
	touch $@

$(chrome-args-gn): conf/args.gn.in | $(chrome-target-dir)
	sed -e 's|@@CLANG_BASE_PATH@@|$(llvm-build-dir)|g' $< > $@

$(libdav1d-rebuilt): $(clang) $(chrome-patched) | $(chrome-dir)
	+cd $(chrome-dir)/third_party/dav1d && \
	./generate_configs.py && \
	./generate_source.py
	touch $@

$(ffmpeg-rebuilt): $(clang) $(chrome-patched) | $(chrome-dir)
	+cd $(chrome-dir)/third_party/ffmpeg && \
	./chromium/scripts/build_ffmpeg.py --branding="ChromeOS" linux ppc64 && \
	./chromium/scripts/generate_gn.py && \
	./chromium/scripts/copy_config.sh
	touch $@

$(libvpx-rebuilt): $(clang) $(chrome-patched) | $(gn-exe) $(chrome-dir)
	+cd $(chrome-dir)/third_party/libvpx && \
	mkdir -p source/config/linux/ppc64 && \
	./generate_gni.sh
	touch $@

$(chrome-configured): $(chrome-args-gn) \
                      $(ffmpeg-rebuilt) \
		      $(libvpx-rebuilt) \
		      $(libdav1d-rebuilt) \
		      | $(gn-exe)
	gn gen --root=$(chrome-dir) $(chrome-target-dir)
	touch $@

$(chrome): $(chrome-configured)
	ninja -C $(chrome-target-dir) -j $(num_threads) \
	    media chrome chrome_sandbox chromedriver clear_key_cdm

$(chrome-rpm-file): $(chrome)
	ninja -C $(chrome-target-dir) -j $(num_threads) stable_rpm

# For the tarball artifact, just extract the files from the RPM, since it only
# includes the files needed and the binaries are already stripped
$(chrome-dist-file): $(chrome-rpm-file)
	rpm2cpio $< | cpio -dium
	mv opt/chromium.org/chromium $(chrome-file-name-base)
	tar cJf $@ $(chrome-file-name-base)

$(chrome-rpm-artifact): $(chrome-rpm-file) | $(artifact-dir)
	mv $< $@

$(chrome-dist-artifact): $(chrome-dist-file) | $(artifact-dir)
	mv $< $@

.PHONY: rpm
rpm: $(chrome-rpm-artifact)

.PHONY: dist
dist: $(chrome-dist-artifact)

.PHONY: llvm-dist
llvm-dist: $(llvm-dist-artifact)

.PHONY: all
all: rpm dist llvm-dist

