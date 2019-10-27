#!/bin/sh
#
# Copyright 2019 Colin Samples
#
# SPDX-License-Identifier: Apache-2.0
#

set -e

make 2>&1 | tee build.log
xz build.log
mv build.log.xz target

