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


