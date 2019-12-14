# Copyright 2019 Colin Samples
#
# SPDX-License-Identifier: Apache-2.0
#

download_url_base := https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download
download_url := $(download_url_base)/$(release_tag)
define release_json_template :=
{
    "name": "Chromium $(release_tag)",
    "tag_name": "$(release_tag)",
    "description": "Chromium $(release_tag)",
    "assets": {
        "links": [
            {
                "name": "$(chrome-rpm-file-name)",
                "url": "$(download_url)/$(chrome-rpm-file-name)"
            },
            {
                "name": "ungoogled-$(chrome-rpm-file-name)",
                "url": "$(download_url)/ungoogled-$(chrome-rpm-file-name)"
            },
            {
                "name": "$(chrome-dist-file-name)",
                "url": "$(download_url)/$(chrome-dist-file-name)"
            },
            {
                "name": "ungoogled-$(chrome-dist-file-name)",
                "url": "$(download_url)/ungoogled-$(chrome-dist-file-name)"
            }
        ]
    }
}
endef

export release_json_template

