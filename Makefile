# Copyright 2019 Colin Samples
#
# SPDX-License-Identifier: Apache-2.0
#

.DEFAULT_GOAL := all

include docker-root/common.mk

release_tag := v$(chrome_ver)-$(chrome_rpm_release)

$(artifact-dir):
	mkdir -p $@

# This is a development environment target that mounts the container's workdir
# in ./build-root and opens a terminal in the container
.PHONY: dev
dev: | $(artifact-dir)
	[ -d build-root ] || cp -R docker-root/ build-root/
	podman build -t chrome-build-image .
	podman run -it \
	    --name=chrome-builder \
	    --rm=true \
	    --volume=$(CURDIR)/build-root:/workdir:z \
	    --volume=$(CURDIR)/$(artifact-dir):/workdir/$(artifact-dir):z \
	    chrome-build-image /usr/bin/bash

.PHONY: tag-release
tag-release:
	@[ $$UID != "0" ] || (echo "ERROR: must be run as normal user" ; exit 1)
	git tag -s $(release_tag) -m "Chromium $(chrome_ver)"

include update-readme-ed-template.mk
.PHONY: update-readme
update-readme:
	cp README.md README.md.bak
	echo "$$update_readme_ed_script" | ed README.md
	@echo
	@echo README.md changed as follows:
	@echo
	@diff --color=always -u README.md.bak README.md || [ $$? = "1" ]
	@echo

include release-json-template.mk
.PHONY: gitlab-upload-release
gitlab-upload-release:
	@[ -n $$GITLAB_API_TOKEN -a -n $$CI_JOB_URL ] || \
	    (echo "GITLAB_API_TOKEN and CI_JOB_URL must be defined." ; exit 1)
	curl --header 'Content-Type: application/json' \
	     --header "PRIVATE-TOKEN: $(GITLAB_API_TOKEN)" \
	     --data "$$release_json_template" \
	     --request POST https://gitlab.com/api/v4/projects/15365525/releases

.PHONY: github-upload-release
github-upload-release:
	./create-github-release.pl \
	    $(release_tag) \
	    $(chrome-rpm-artifact) \
	    $(chrome-dist-artifact)

.PHONY: clean
clean:
	rm -rf $(artifact-dir)
	rm -rf build-root
	rm -f *.stamp
	rm -f *.log
	rm -f README.bak
	podman rm -f chrome-builder || [ $$? = "1" ]
	podman rmi -f chrome-build-image || [ $$? = "1" ]

.PHONY: all
all: dev

