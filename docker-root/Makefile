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

llvm-archive := llvm-$(llvm_rev)-ppc64le.tar.gz
llvm-dir := $(CURDIR)/llvm-$(llvm_rev)-ppc64le

chrome-archive := chromium-$(chrome_ver).tar.xz
chrome-dir := $(CURDIR)/chromium-$(chrome_ver)

chrome-mk-prereqs := $(gn-exe) $(llvm-dir) $(chrome-dir)

export chrome-dir clang llvm-dir gn-exe gn-bin-dir

###############################################################################
# External Assets
###############################################################################
gn_url := https://gn.googlesource.com/gn
llvm_url := https://gitlab.com/chromium-ppc64le/llvm-builds/-/jobs/357854783/artifacts/raw/target/$(llvm-archive)
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
		    -Wno-unused-private-field
opt_flags := -mcpu=power9 -mtune=power9

export CFLAGS ?= $(ignored_warnings) $(opt_flags)
export CXXFLAGS ?= $(ignored_warnings) $(opt_flags)
export LDFLAGS += -lm

###############################################################################
# GN
###############################################################################
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
	wget $(llvm_url)

$(llvm-dir): | $(llvm-archive)
	tar xzf $|

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

.PHONY: all
all: chromium

