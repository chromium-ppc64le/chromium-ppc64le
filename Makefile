# Copyright 2019 Colin Samples
#
# SPDX-License-Identifier: Apache-2.0
#

.DEFAULT_GOAL := all

include docker-root/common.mk

release_tag := v$(chrome_ver)-$(chrome_rpm_release)
download_url_base := https://github.com/vddvss/chromium-ppc64le/releases/download
download_url := $(download_url_base)/$(release_tag)

# Targets
rpm-signed := rpm-signed.stamp

# ed script to update the README for a new release
define update_readme_ed_script :=
H
/<!-- RPM INSTALL COMMAND -->/+2c
sudo dnf install $(download_url)/$(chrome-rpm-file-name)
.

/<!-- ARCHIVE TABLE -->/+2x
s!sudo dnf install \($(download_url_base)/\(.*\)/.*\)\.ppc64le\.rpm!| \2 | [rpm](\1.ppc64le.rpm) | [.tar.xz](\1.tar.xz) |!

/<!-- CURRENT TABLE -->/+3c
| [$(release_tag)]($(download_url)/$(chrome-rpm-file-name)) | [$(release_tag)]($(download_url)/$(chrome-dist-file-name)) |
.

g/latest/s|\[latest\]([^)]\+\.tar\.xz)|[latest]($(download_url)/$(chrome-dist-file-name))|g
w
endef
export update_readme_ed_script

$(artifact-dir):
	mkdir -p $@

build-root:
	mkdir -p $@

$(chrome-rpm-artifact): | $(artifact-dir)
	buildah bud -t chrome-build-image .
	podman run \
	    --env-host \
	    --name=chrome-builder \
	    --rm=true \
	    --volume=$(CURDIR)/$(artifact-dir):/workdir/$(artifact-dir):z \
	    chrome-build-image

$(chrome-dist-artifact): $(chrome-rpm-artifact)
$(llvm-dist-artifact): $(chrome-rpm-artifact)

$(rpm-signed): $(chrome-rpm-artifact)
	rpm \
	    -D "_gpg_name Chromium Unofficial PPC64LE Packaging" \
	    --addsign $<
	touch $@

$(chrome-dist-artifact).asc: $(chrome-dist-artifact)
	gpg \
	    --detach-sign \
	    --armor \
	    -u 'Chromium Unofficial PPC64LE Packaging' \
	    $<

$(artifact-dir)/sha265sums: $(rpm-signed) $(chrome-dist-artifact)
	cd $(artifact-dir) && \
	    sha256sum $(chrome-rpm-file-name) $(chrome-dist-file-name) > $(@F)

$(artifact-dir)/sha265sums.asc: $(artifact-dir)/sha265sums
	gpg \
	    --clear-sign \
	    --armor \
	    -u 'Chromium Unofficial PPC64LE Packaging' \
	    $<

# This is a development environment target that mounts the container's workdir
# in ./build-root and opens a terminal in the container
.PHONY: dev
dev: | $(artifact-dir) build-root
	cp -R docker-root/* build-root
	podman build -t chrome-build-image .
	podman run -it \
	    --name=chrome-builder \
	    --rm=true \
	    --volume=$(CURDIR)/build-root:/workdir:z \
	    --volume=$(CURDIR)/$(artifact-dir):/workdir/$(artifact-dir):z \
	    chrome-build-image /usr/bin/bash

.PHONY: gitlab-build
gitlab-build: | $(artifact-dir)
	buildah version
	buildah bud -t chrome-build-image . && \
	CTRNAME=$$(buildah from chrome-build-image) && \
	printenv -0 | xargs -I{} -0 buildah config --env "{}" $$CTRNAME && \
	buildah run \
	    --mount=type=bind,source=$(CURDIR)/$|,destination=/workdir/$| \
	    $$CTRNAME -- /usr/bin/bash -c \
	    'make -w -j16 && make clean-chrome && make -w -j16 UNGOOGLED=1'

.PHONY: sign-rpm
sign-rpm: $(rpm-signed)

.PHONY: sign-tarball
sign-tarball: $(chrome-dist-artifact).asc

.PHONY: sign
sign: $(rpm-signed) $(chrome-dist-artifact).asc

.PHONY: chown
chown:
	chown -R $(SUDO_UID):$(SUDO_GID) $(artifact-dir)

.PHONY: release
release: $(chrome-dist-artifact).asc $(artifact-dir)/sha265sums.asc

.PHONY: install
install: release
	dnf install ./$(chrome-rpm-artifact)

.PHONY: update-readme
update-readme:
	cp README.md README.md.bak
	echo "$$update_readme_ed_script" | ed README.md
	@echo
	@echo README.md changed as follows:
	@echo
	@diff --color=always -u README.md.bak README.md || [ $$? = "1" ]
	@echo

.PHONY: tag-release
tag-release:
	@[ $$UID != "0" ] || (echo "ERROR: must be run as normal user" ; exit 1)
	git tag -s $(release_tag) -m "Chromium $(chrome_ver)"

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
all: $(chrome-rpm-artifact) $(chrome-dist-artifact) $(llvm-dist-artifact)

