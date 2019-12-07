# Copyright 2019 Colin Samples
#
# SPDX-License-Identifier: Apache-2.0
#

.DEFAULT_GOAL := all

include common.mk

###############################################################################
# Targets
###############################################################################
gn-bin-dir := $(CURDIR)/gn/out
gn-exe := $(gn-bin-dir)/gn

llvm-archive := llvm-$(llvm_rev)-ppc64le.tar.zstd
llvm-dir := $(CURDIR)/llvm-$(llvm_rev)-ppc64le

chrome-archive := chromium-$(chrome_ver).tar.xz
chrome-dir := $(CURDIR)/chromium-$(chrome_ver)

chrome-mk-prereqs := $(gn-exe) $(llvm-dir) $(chrome-dir)

export chrome-dir llvm-dir gn-exe gn-bin-dir

###############################################################################
# External Assets
###############################################################################
gn_url := https://gn.googlesource.com/gn
llvm_url := https://github.com/chromium-ppc64le/llvm-builds/releases/download/v$(llvm_rev)/$(llvm-archive)
chrome_url := \
    https://commondatastorage.googleapis.com/chromium-browser-official/$(chrome-archive)

###############################################################################
# Environment
###############################################################################
ignored_warnings := -Wno-shorten-64-to-32 \
		    -Wno-deprecated-declarations \
		    -Wno-deprecated \
		    -Wno-unused-function \
		    -Wno-unused-variable \
		    -Wno-implicit-float-conversion \
		    -Wno-unused-private-field \
		    -Wno-string-plus-int \
		    -Wno-constant-conversion \
		    -Wno-incompatible-pointer-types-discards-qualifiers \
		    -Wno-unused-label
opt_flags := -mcpu=power9 -mtune=power9

export CFLAGS ?= $(ignored_warnings) $(opt_flags)
export CXXFLAGS ?= $(ignored_warnings) $(opt_flags)
export LDFLAGS += -lm

export CCACHE_BASEDIR := $(CURDIR)
export CCACHE_COMPILERCHECK := content
export CCACHE_SLOPPINESS := file_macro,time_macros
export CCACHE_MAXSIZE ?= 25G
export CCACHE_NLEVELS := 3
export CCACHE_DIR := $(CURDIR)/.ccache

###############################################################################
# GN
###############################################################################
gn:
	git clone $(gn_url)

$(gn-exe): export CC := ccache /usr/bin/clang
$(gn-exe): export CXX := ccache /usr/bin/clang++
$(gn-exe): | gn
	cd gn && \
	python build/gen.py && \
	ninja -j $(NUM_THREADS) -C out
	ccache --show-stats

###############################################################################
# LLVM
###############################################################################
$(llvm-archive):
	wget -q $(llvm_url)

$(llvm-dir): | $(llvm-archive)
	tar --zstd -xf $|
	patch -d $@ -p1 < $(CURDIR)/patches/llvm/fix-altivec.patch

###############################################################################
# Chrome
###############################################################################
$(chrome-archive):
	wget -q $(chrome_url)

$(chrome-dir): | $(chrome-archive)
	tar xf $|

.PHONY: chromium
chromium: | $(chrome-mk-prereqs)
	$(MAKE) -f chromium.mk

.PHONY: chromium.%
chromium.%: | $(chrome-mk-prereqs)
	$(MAKE) -f chromium.mk $*

.PHONY: ungoogled-chromium
ungoogled-chromium: | $(chrome-mk-prereqs)
	$(MAKE) -f chromium.mk UNGOOGLED=1

.PHONY: both-chromium
both-chromium: | $(chrome-mk-prereqs)
	$(MAKE) -f chromium.mk
	$(MAKE) -f chromium.mk clean-patches clean-config
	$(MAKE) -f chromium.mk UNGOOGLED=1

.PHONY: all
all: chromium

