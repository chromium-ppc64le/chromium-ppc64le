# Copyright 2019 Colin Samples
#
# SPDX-License-Identifier: Apache-2.0
#

# llvm_rev is from $(chrome-dir)/tools/clang/scripts/update.py
llvm_rev := 8455294f2ac13d587b13d728038a9bffa7185f2b
cpf_rev := d6b7ab92474eb27d773d3e4578a1e8bd71586075
chrome_ver := 78.0.3904.87
# the rpm release number is hardcoded in
# $(chrome-dir)/chrome/installer/linux/common/installer.include, but it should
# be bumped when releasing a new rpm with the same version number
chrome_rpm_release := 1

file-name-base := chromium-browser-stable-$(chrome_ver)-$(chrome_rpm_release)
rpm-file-name := $(file-name-base).ppc64le.rpm
dist-file-name := $(file-name-base).tar.xz

artifact-dir := target

