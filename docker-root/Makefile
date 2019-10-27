# Copyright 2019 Colin Samples
#
# SPDX-License-Identifier: Apache-2.0
#

.DEFAULT_GOAL := all

num_threads := 16

include common.mk

gn_url := https://gn.googlesource.com/gn
llvm_url := https://github.com/llvm/llvm-project/archive/$(llvm_rev).tar.gz
cpf_url := https://github.com/shawnanastasio/chromium_power
chrome_url := https://commondatastorage.googleapis.com/chromium-browser-official/chromium-$(chrome_ver).tar.xz

# Targets
gn-bin-dir := $(CURDIR)/gn/out
gn-exe := $(gn-bin-dir)/gn

llvm-archive := $(llvm_rev).tar.gz
llvm-dir := $(CURDIR)/llvm-project-$(llvm_rev)
llvm-build-dir := $(CURDIR)/llvm-build
clang := $(llvm-build-dir)/bin/clang

cpf-dir := chromium_power

chrome-archive := chromium-$(chrome_ver).tar.xz
chrome-dir := $(CURDIR)/chromium-$(chrome_ver)
chrome-target := out/Release
chrome-target-dir := $(chrome-dir)/$(chrome-target)
chrome-args-gn := $(chrome-target-dir)/args.gn
chrome-rpm-file := $(chrome-target-dir)/$(rpm-file-name)
chrome-dist-file := $(chrome-target-dir)/$(dist-file-name)
chrome := $(chrome-target-dir)/chrome

llvm-patched := llvm-patched.stamp
ffmpeg-rebuilt := ffmpeg-rebuilt.stamp
libvpx-rebuilt := libvpx-rebuilt.stamp
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

ignored_warnings := -Wno-shorten-64-to-32 -Wno-deprecated-declarations -Wno-deprecated
opt_flags := -mcpu=power9 -mtune=power9

export CFLAGS ?= $(ignored_warnings) $(opt_flags)
export CXXFLAGS ?= $(ignored_warnings) $(opt_flags)
export LDFLAGS += -lm

ORIG_PATH := $(PATH)
export PATH := $(gn-bin-dir):$(ORIG_PATH)

gn:
	git clone $(gn_url)

$(gn-exe): | gn
	cd gn && \
	env CC=$(ORIG_CC) CXX=$(ORIG_CXX) AR=$(ORIG_AR) python build/gen.py && \
	ninja -j $(num_threads) -C out

$(llvm-archive):
	wget $(llvm_url)

$(llvm-dir): | $(llvm-archive)
	tar xzf $|

$(llvm-patched): llvm-lrint.patch | $(llvm-dir)
	patch -d $| -p1 < $<
	touch $@

$(llvm-build-dir): $(llvm-patched)
	mkdir -p $@

$(llvm-build-dir)/CMakeCache.txt: | $(llvm-build-dir) $(llvm-dir)
	cmake -S $(llvm-dir)/llvm -B $(llvm-build-dir) \
	    -G "Ninja" \
	    -DCMAKE_BUILD_TYPE=Release \
	    -DLLVM_ENABLE_PROJECTS="clang;lld" \
	    -DLLVM_TARGETS_TO_BUILD="PowerPC" \
	    -DCMAKE_AR=/usr/bin/ar \
	    -DCMAKE_C_COMPILER=/usr/bin/clang \
	    -DCMAKE_CXX_COMPILER=/usr/bin/clang++

$(clang): $(llvm-build-dir)/CMakeCache.txt
	ninja -C $(llvm-build-dir) -j $(num_threads)

$(cpf-dir):
	git clone $(cpf_url) $@
	cd $@ && git checkout $(cpf_rev)

$(chrome-archive):
	wget $(chrome_url)

$(chrome-dir): | $(chrome-archive)
	tar xf $|

$(chrome-target-dir): | $(chrome-dir)
	mkdir -p $@

$(chrome-patched): $(cpf-dir) enable-vaapi.patch enable-rpm-build.patch Yarn.patch | $(chrome-dir)
	cd $< && python3 cpf.py $|
	patch -d $| -p1 < $(word 2,$^)
	patch -d $| -p1 < $(word 3,$^)
	patch -d $| -p1 < $(word 4,$^)
	touch $@

$(chrome-args-gn): args.gn.in | $(chrome-target-dir)
	sed -e 's|@@CLANG_BASE_PATH@@|$(llvm-build-dir)|g' $< > $@

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

$(chrome-configured): $(chrome-args-gn) $(ffmpeg-rebuilt) $(libvpx-rebuilt) | $(gn-exe)
	gn gen --root=$(chrome-dir) $(chrome-target-dir)
	touch $@

$(chrome): $(chrome-configured)
	ninja -C $(chrome-target-dir) media chrome chrome_sandbox -j $(num_threads)

$(chrome-rpm-file): $(chrome)
	ninja -C $(chrome-target-dir) stable_rpm -j $(num_threads)

# For the tarball artifact, just extract the files from the RPM, since it only
# includes the files needed and the binaries are already stripped
$(chrome-dist-file): $(chrome-rpm-file)
	rpm2cpio $< | cpio -dium
	mv opt/chromium.org/chromium $(file-name-base)
	tar cJf $@ $(file-name-base)

$(artifact-dir)/$(rpm-file-name): $(chrome-rpm-file)
	mv $< $@

$(artifact-dir)/$(dist-file-name): $(chrome-dist-file)
	mv $< $@

.PHONY: rpm
rpm: $(artifact-dir)/$(rpm-file-name)

.PHONY: dist
dist: $(artifact-dir)/$(dist-file-name)

.PHONY: all
all: rpm dist

