# Unofficial Chromium Builds for PPC64LE

This repository contains prebuilt RPMs and tarballs for Chromium on ppc64le
along with the build scripts.

These are largely the same as upstream's. For an alternative, you can use https://github.com/leo-lb/ungoogled-chromium

# Installation

The easiest way to install is to add the repo...

## Adding DNF Repo

```
sudo dnf config-manager --add-repo=https://github.com/vddvss/chromium-ppc64le/raw/master/chromium-ppc64le.repo
```

Alternativly, you can download the 
[`chromium-ppc64le.repo`](https://github.com/vddvss/chromium-ppc64le/raw/master/chromium-ppc64le.repo)
file from this repository and place it in `/etc/yum.repos.d`.

## Installing

After adding the repository, run:

```
sudo dnf install chromium-browser-stable
```

or

```
sudo dnf install ungoogled-chromium-browser-stable
```

## Quick download

<!-- CURRENT TABLE -->
| RPM | .tar.xz |
| --- | ------- |
| [v78.0.3904.108-1](https://github.com/vddvss/chromium-ppc64le/releases/download/v78.0.3904.108-1/chromium-browser-stable-78.0.3904.108-1.ppc64le.rpm) | [v78.0.3904.108-1](https://github.com/vddvss/chromium-ppc64le/releases/download/v78.0.3904.108-1/chromium-browser-stable-78.0.3904.108-1.tar.xz) |

## Installing the RPM

### Importing GPG key (only needed for initial install)

```
sudo rpm --import https://github.com/vddvss/chromium-ppc64le/raw/master/RPM-GPG-KEY-chromium-ppc64le
```

### Installing/Upgrading

<!-- RPM INSTALL COMMAND -->
```
sudo dnf install https://github.com/vddvss/chromium-ppc64le/releases/download/v78.0.3904.108-1/chromium-browser-stable-78.0.3904.108-1.ppc64le.rpm
```

## Downloading a prebuilt binary

Just download the [latest](https://github.com/vddvss/chromium-ppc64le/releases/download/v78.0.3904.108-1/chromium-browser-stable-78.0.3904.108-1.tar.xz) and extract it.

## Building from source

```
sudo make -j16
```

Note that with the configuration in this repo, you will need at least 64G of RAM
and at least 8 cores. 

## Notes on Binaries

### Patches included

* [Patches](https://github.com/shawnanastasio/chromium_power) to enable building
  on PPC64LE
* [Patch](docker-root/patches/chrome/enable-rpm-build.patch) to enable RPM
  building for PPC64LE
* [Patch](docker-root/patches/chrome/enable-vaapi.patch) to enable
  GPU-accelerated video decoding
* [Patch](docker-root/patches/chrome/change-user-agent.patch) to change the
  browser's user agent string to be the same as the official Chrome build on
  Linux, which helps reduce the browser's fingerprinting surface

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
| v78.0.3904.87-1 | [rpm](https://github.com/vddvss/chromium-ppc64le/releases/download/v78.0.3904.87-1/chromium-browser-stable-78.0.3904.87-1.ppc64le.rpm) | [.tar.xz](https://github.com/vddvss/chromium-ppc64le/releases/download/v78.0.3904.87-1/chromium-browser-stable-78.0.3904.87-1.tar.xz) |
| v78.0.3904.70-1 | [rpm](https://github.com/vddvss/chromium-ppc64le/releases/download/v78.0.3904.70-1/chromium-browser-stable-78.0.3904.70-1.ppc64le.rpm) | [.tar.xz](https://github.com/vddvss/chromium-ppc64le/releases/download/v78.0.3904.70-1/chromium-browser-stable-78.0.3904.70-1.tar.xz) |

