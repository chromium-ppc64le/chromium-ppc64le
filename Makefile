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
rpm-file := $(artifact-dir)/$(rpm-file-name)
dist-file := $(artifact-dir)/$(dist-file-name)

rpm-signed := rpm-signed.stamp

# ed script to update the README for a new release
define update_readme_ed_script :=
H
/<!-- RPM INSTALL COMMAND -->/+2c
sudo dnf install $(download_url)/$(rpm-file-name)
.

/<!-- ARCHIVE TABLE -->/+2x
s!sudo dnf install \($(download_url_base)/\(.*\)/.*\)\.ppc64le\.rpm!| \2 | [rpm](\1.ppc64le.rpm) | [.tar.xz](\1.tar.xz) |!

/<!-- CURRENT TABLE -->/+3c
| [$(release_tag)]($(download_url)/$(rpm-file-name)) | [$(release_tag)]($(download_url)/$(dist-file-name)) |
.

g/latest/s|\[latest\]([^)]\+\.tar\.xz)|[latest]($(download_url)/$(dist-file-name))|g
w
endef
export update_readme_ed_script

$(artifact-dir):
	mkdir -p $@

$(rpm-file): | $(artifact-dir)
	podman build -t chrome-build-image .
	podman run \
	    --name=chrome-builder \
	    --rm=true \
	    --volume=$(CURDIR)/$|:/workdir/$|:z \
	    chrome-build-image

$(dist-file): $(rpm-file)

$(rpm-signed): $(rpm-file)
	rpm \
	    -D "_gpg_name Chromium Unofficial PPC64LE Packaging" \
	    --addsign $<
	touch $@

$(artifact-dir)/$(dist-file).asc: $(dist-file)
	gpg \
	    --detach-sign \
	    --armor \
	    -u 'Chromium Unofficial PPC64LE Packaging' \
	    $<

$(artifact-dir)/sha265sums: $(rpm-signed) $(dist-file)
	cd $(artifact-dir) && sha256sum $(rpm-file-name) $(dist-file-name) > $(@F)

$(artifact-dir)/sha265sums.asc: $(artifact-dir)/sha265sums
	gpg \
	    --clear-sign \
	    --armor \
	    -u 'Chromium Unofficial PPC64LE Packaging' \
	    $<

.PHONY: sign-rpm
sign-rpm: $(rpm-signed)

.PHONY: sign-tarball
sign-tarball: $(artifact-dir)/$(dist-file).asc

.PHONY: sign
sign: $(rpm-signed) $(artifact-dir)/$(dist-file).asc

.PHONY: chown
chown:
	chown -R $(SUDO_UID):$(SUDO_GID) $(artifact-dir)

.PHONY: release
release: $(artifact-dir)/$(dist-file).asc $(artifact-dir)/sha265sums.asc

.PHONY: install
install: release
	dnf install ./$(rpm-file)

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
	git tag -s $(release_tag)

.PHONY: clean
clean:
	rm -rf $(artifact-dir)
	rm -f *.stamp
	rm -f *.log
	rm -f README.bak
	podman rm -f chrome-builder || [ $$? = "1" ]
	podman rmi -f chrome-build-image || [ $$? = "1" ]

.PHONY: all
all: $(rpm-file) $(dist-file)

