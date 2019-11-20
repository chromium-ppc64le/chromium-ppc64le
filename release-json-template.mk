define release_json_template :=
{
    "name": "Chromium $(release_tag)",
    "tag_name": "$(release_tag)",
    "description": "Chromium $(release_tag)",
    "assets": {
        "links": [
            {
                "name": "$(chrome-rpm-file-name)",
                "url": "$(CI_JOB_URL)/artifacts/raw/target/$(chrome-rpm-file-name)"
            },
            {
                "name": "ungoogled-$(chrome-rpm-file-name)",
                "url": "$(CI_JOB_URL)/artifacts/raw/target/ungoogled-$(chrome-rpm-file-name)"
            },
            {
                "name": "$(chrome-dist-file-name)",
                "url": "$(CI_JOB_URL)/artifacts/raw/target/$(chrome-dist-file-name)"
            },
            {
                "name": "ungoogled-$(chrome-dist-file-name)",
                "url": "$(CI_JOB_URL)/artifacts/raw/target/ungoogled-$(chrome-dist-file-name)"
            }
        ]
    }
}
endef

export release_json_template

