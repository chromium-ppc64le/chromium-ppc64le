# Copyright 2019 Colin Samples
#
# SPDX-License-Identifier: Apache-2.0
#

.DEFAULT_GOAL := all

export NUM_THREADS ?= 16
export CONCURRENT_LINKS ?= 2

include common.mk

gn_url := https://gn.googlesource.com/gn
llvm_url := https://github.com/llvm/llvm-project/archive/$(llvm_rev).tar.gz
chrome_url := https://commondatastorage.googleapis.com/chromium-browser-official/chromium-$(chrome_ver).tar.xz

###############################################################################
# Targets
###############################################################################
gn-bin-dir := $(CURDIR)/gn/out
gn-exe := $(gn-bin-dir)/gn

llvm-archive := $(llvm_rev).tar.gz
llvm-dir := $(CURDIR)/llvm-project-$(llvm_rev)
llvm-build-dir := $(CURDIR)/llvm-build
llvm-patch-series-dir := $(CURDIR)/patches/llvm
llvm-patched := llvm-patched.stamp
clang := $(llvm-build-dir)/bin/clang

chrome-archive := chromium-$(chrome_ver).tar.xz
chrome-dir := $(CURDIR)/chromium-$(chrome_ver)

chrome-mk-prereqs := $(gn-exe) $(clang) $(chrome-dir)

export chrome-dir clang llvm-build-dir gn-exe

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

.PHONY: standard-chromium
standard-chromium: | $(chrome-mk-prereqs)
	$(MAKE) -f chromium.mk

.PHONY: ungoogled-chromium
ungoogled-chromium: | $(chrome-mk-prereqs)
	$(MAKE) -f chromium.mk UNGOOGLED=1

.PHONY: chromium
chromium: | $(chrome-mk-prereqs)
	$(MAKE) -f chromium.mk
	$(MAKE) -f chromium.mk clean-patches clean-config
	$(MAKE) -f chromium.mk UNGOOGLED=1

.PHONY: llvm-dist
llvm-dist: $(llvm-dist-artifact)

.PHONY: all
all: chromium

