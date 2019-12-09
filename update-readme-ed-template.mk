# Copyright 2019 Colin Samples
#
# SPDX-License-Identifier: Apache-2.0
#

download_url_base := https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download
download_url := $(download_url_base)/$(release_tag)

# ed script to update the README for a new release
define update_readme_ed_script :=
H
/<!-- RPM INSTALL COMMAND -->/+2c
sudo rpm -Uvh $(download_url)/$(chrome-rpm-file-name)
.

/^\[latest standard build\].\+)$$/c
[latest standard build]($(download_url)/$(chrome-rpm-file-name))
.

/<!-- RPM UNGOOGLED INSTALL COMMAND -->/+2c
sudo rpm -Uvh $(download_url)/ungoogled-$(chrome-rpm-file-name)
.

/^\[latest Ungoogled Chromium build\].\+)$$/c
[latest Ungoogled Chromium build]($(download_url)/ungoogled-$(chrome-rpm-file-name))
.

/<!-- CURRENT ROW -->/+;+6c
    <tr>
      <td>$(release_tag)</td>
      <td align="center"><a href="$(download_url)/$(chrome-rpm-file-name)">rpm</a></td>
      <td align="center"><a href="$(download_url)/$(chrome-dist-file-name)">.tar.xz</a></td>
      <td align="center"><a href="$(download_url)/ungoogled-$(chrome-rpm-file-name)">rpm</a></td>
      <td align="center"><a href="$(download_url)/ungoogled-$(chrome-dist-file-name)">.tar.xz</a></td>
    </tr>
.

/<!-- ARCHIVE ROW -->/x

w
endef
export update_readme_ed_script

