# Copyright 2019 Colin Samples
#
# SPDX-License-Identifier: Apache-2.0
#

NUM_THREADS ?= 16
CONCURRENT_LINKS ?= 2
USE_LTO ?= true

artifact-dir := target

# llvm_rev is from $(chrome-dir)/tools/clang/scripts/update.py
llvm_rev := 4e0d9925d6a3561449bdd8def27fd3f3f1b3fb9f
chrome_ver := 83.0.4103.97
chrome_channel := stable
# the rpm release number is hardcoded in
# $(chrome-dir)/chrome/installer/linux/common/installer.include, but it should
# be bumped when releasing a new rpm with the same version number
chrome_rpm_release := 1

ifdef UNGOOGLED
dist-prefix := ungoogled-
endif

chrome-file-name-base := \
    $(dist-prefix)chromium-browser-$(chrome_channel)-$(chrome_ver)-$(chrome_rpm_release)
chrome-rpm-file-name := $(chrome-file-name-base).ppc64le.rpm
chrome-dist-file-name := $(chrome-file-name-base).tar.xz
chrome-rpm-artifact := $(artifact-dir)/$(chrome-rpm-file-name)
chrome-dist-artifact := $(artifact-dir)/$(chrome-dist-file-name)

