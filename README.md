# Unofficial Chromium Builds for PPC64LE

This repository contains prebuilt RPMs and tarballs for Chromium on ppc64le
along with the build scripts.

These are largely the same as upstream's. For an alternative, you can use https://github.com/leo-lb/ungoogled-chromium

## Quick download

<!-- CURRENT TABLE -->
| RPM | .tar.xz |
| --- | ------- |
| [v78.0.3904.70-1](https://github.com/vddvss/chromium-ppc64le/releases/download/v78.0.3904.70-1/chromium-browser-stable-78.0.3904.70-1.ppc64le.rpm) | [v78.0.3904.70-1](https://github.com/vddvss/chromium-ppc64le/releases/download/v78.0.3904.70-1/chromium-browser-stable-78.0.3904.70-1.tar.xz) |

## Installing the RPM

### Importing GPG key (only needed for initial install)

```
sudo rpm --import https://github.com/vddvss/chromium-ppc64le/raw/master/RPM-GPG-KEY-chromium-ppc64le
```

### Installing/Upgrading

<!-- RPM INSTALL COMMAND -->
```
sudo dnf install https://github.com/vddvss/chromium-ppc64le/releases/download/v78.0.3904.70-1/chromium-browser-stable-78.0.3904.70-1.ppc64le.rpm
```

## Downloading a prebuilt binary

Just download the [latest](https://github.com/vddvss/chromium-ppc64le/releases/download/v78.0.3904.70-1/chromium-browser-stable-78.0.3904.70-1.tar.xz) and extract it.

## Building from source

```
sudo make -j16
```

## Notes on Binaries

### Patches included

* [Patches](https://github.com/shawnanastasio/chromium_power) to enable building
  on PPC64LE
* [Patch](docker-root/enable-rpm-build.patch) to enable RPM building for PPC64LE
* [Patch](docker-root/enable-vaapi.patch) to enable GPU-accelerated video
  decoding

### Features enabled

* ThinLTO
* PulseAudio integration
* Non-free codecs

### Platform support

These uses the rpm packaging files from the chromium build tree.

The RPMs should work on all RPM distros, but they are only tested on Fedora.

## Issues

### TODO

#### `dpkg` support

The chromium tree includes files to build packages for Debian-based systems. I
haven't built these packages, since I can't easily test them, and the packaging
files in the chromium tree seem to make more assumptions about the platform.

## Previous versions

<!-- ARCHIVE TABLE -->
| Version  | RPM | .tar.xz |
| -------- | --- | --------|

