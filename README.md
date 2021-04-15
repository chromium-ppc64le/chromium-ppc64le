# Unofficial Chromium Builds for PPC64LE

This repository contains a framework for building and distributing RPMs and
tarballs for Chromium on ppc64le. The repository provides two flavors of
Chromium, one that is largely the same as upstream's, and another containing the
[Ungoogled Chromium patchset](https://gitlab.com/chromium-ppc64le/ungoogled-chromium),
which removes dependencies on Google web services. It also features some tweaks
to enhance privacy, control, and transparency (almost all of which require
manual activation or enabling).

## Installation

The easiest way to install is to add the repository, which is currently only
available for Fedora 29, RHEL 8.3, CentOS 8.2 or newer. It might also work
with distribution with glibc 2.28 or newer.

### Fedora, RHEL, and CentOS

#### Adding DNF Repo

```bash
sudo dnf config-manager --add-repo=https://gitlab.com/chromium-ppc64le/chromium-ppc64le/raw/master/chromium-ppc64le.repo
```

Alternatively, you can download the
[`chromium-ppc64le.repo`](https://gitlab.com/chromium-ppc64le/chromium-ppc64le/raw/master/chromium-ppc64le.repo)
file from this repository and place it in `/etc/yum.repos.d`.

#### Installing

After adding the repository, run:

##### Standard Chromium

```bash
sudo dnf install chromium-browser-stable
```

##### Ungoogled Chromium

```bash
sudo dnf install ungoogled-chromium-browser-stable
```

###### Note for Existing Users of Ungoogled Chromium

In order to allow parallel installation of both versions of Chromium, This
repository contains a patch to change the default location of the Ungoogled
Chromium profile from `~/.config/chromium` to `~/.config/ungoogled-chromium`.

To use your existing profile with Ungoogled Chromium, simply run:

```
mv ~/.config/chromium ~/.config/ungoogled-chromium
```

### Other Distributions

#### Current Release Download

<table>
  <thead>
    <tr>
      <th>Version</th>
      <th colspan=2>Standard Chromium</th>
      <th colspan=2>Ungoogled Chromium</th>
    </tr>
  </thead>
  <tbody>
<!-- CURRENT ROW -->
    <tr>
      <td>v86.0.4240.198-1</td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v86.0.4240.198-1/chromium-browser-stable-86.0.4240.198-1.ppc64le.rpm">rpm</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v86.0.4240.198-1/chromium-browser-stable-86.0.4240.198-1.tar.xz">.tar.xz</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v86.0.4240.198-1/ungoogled-chromium-browser-stable-86.0.4240.198-1.ppc64le.rpm">rpm</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v86.0.4240.198-1/ungoogled-chromium-browser-stable-86.0.4240.198-1.tar.xz">.tar.xz</a></td>
    </tr>
  </tbody>
</table>

#### Other RPM Distributions

Installing on other distributions that use RPM, such as openSUSE, should be
possible, but it has not been tested.

##### Installing/Upgrading

###### Standard Chromium

<!-- RPM INSTALL COMMAND -->
```bash
sudo rpm -Uvh https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v86.0.4240.198-1/chromium-browser-stable-86.0.4240.198-1.ppc64le.rpm
```

###### Ungoogled Chromium

<!-- RPM UNGOOGLED INSTALL COMMAND -->
```bash
sudo rpm -Uvh https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v86.0.4240.198-1/ungoogled-chromium-browser-stable-86.0.4240.198-1.ppc64le.rpm
```

#### Other Distributions

Just download the
[latest standard build](https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v86.0.4240.198-1/chromium-browser-stable-86.0.4240.198-1.tar.xz)
or the
[latest Ungoogled Chromium build](https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v86.0.4240.198-1/ungoogled-chromium-browser-stable-86.0.4240.198-1.tar.xz)
and extract it.

## Building from Source

```bash
git clone --recurse-submodules https://gitlab.com/chromium-ppc64le/chromium-ppc64le
cd chromium-ppc64le
make dev
```

This will build a container using [`podman`](https://podman.io/), open a shell
in the container, and bind mount the container's working directory to
a `build-root/` directory in the current directory. From the container, run:

```bash
make chromium -j16
```

or, for Ungoogled Chromium:

```bash
make ungoogled-chromium -j16
```

To build both flavors, run:

```bash
make both-chromium -j16
```

### Resource Requirements for Build

Note that with the configuration in this repo, the build uses 32GB of RAM at its
peak, about 100GB of disk space, 16 CPU threads for most of the build, and at
certain points in the build 30 threads. Resource requirements can be reduced by
altering the below environment variables.

### Environment Variables Controlling Build

Certain environment variables control aspects of the build and are listed below
along with their default values.

```bash
# Number of threads to use for multithreaded operations in the build. The build
# uses `ninja` for building and enables multithreaded compression. These do not
# respect the -j thread passed to `make`.
NUM_THREADS=16

# Whether to build using Link-Time Optimization. This increases RAM requirements
# for the build.
USE_LTO=true

# Number of link jobs to do concurrently. Each concurrent job uses about 16GB
# of RAM and 8 threads. These may be in addition to the threads specified by the
# NUM_THREADS environment variable, so having 2 concurrent link jobs will cause
# the build to use a maximum of 30 threads, as in this formula:
#      (NUM_THREADS - CONCURRENT_LINKS) + (8 * CONCURRENT_LINKS).
CONCURRENT_LINKS=2

# Size of the `ccache` cache. To disable `ccache`, set the CCACHE_DISABLE
# environment variable
CCACHE_MAXSIZE=25G

```

## Notes on Binaries

### Patches Included

* [Patches](https://github.com/shawnanastasio/chromium_power) to enable building
  on PPC64LE
* [Patch](docker-root/patches/chrome/enable-rpm-build.patch) to enable RPM
  building for PPC64LE
* [Patch](docker-root/patches/chrome/enable-vaapi.patch) to enable
  GPU-accelerated video decoding
* [Patch](docker-root/patches/chrome/change-user-agent.patch) to change the
  browser's user agent string to be the same as the official Chrome build on
  Linux, which helps reduce the browser's fingerprinting surface
* [Patch](docker-root/patches/chrome/skia-vsx-instructions.patch) to enable use
  of POWER VSX instructions in the skia rendering engine

### Features Enabled

* Link-time optimized builds
* PulseAudio integration
* Non-free codecs

### Build Logs

The logs for the build and repo creation are available
[under GitLab pipelines](https://gitlab.com/chromium-ppc64le/chromium-ppc64le/pipelines).

## Issues

### TODO

#### GPG Signing

Currently, the builds are not GPG signed, as signing the builds would require
storage of the private key and password in an unsafe manner on GitLab's servers.
Options for proper signing are currently being evaluated.

#### `dpkg` Support

The chromium tree includes files to build packages for Debian-based systems.
These haven't been built, since the maintainers can't easily test them, and the
packaging files in the chromium tree seem to make more assumptions about the
platform.

## License

Most files in this repository are licensed under the
[Apache 2.0 license](LICENSE).

Patches are licensed under the license to the files they patch.

Submodules are licensed under the respective license in the repository.

## Previous Versions

<!-- ARCHIVE TABLE -->
<table>
  <thead>
    <tr>
      <th>Version</th>
      <th colspan=2>Standard Chromium</th>
      <th colspan=2>Ungoogled Chromium</th>
    </tr>
  </thead>
  <tbody>
<!-- ARCHIVE ROW -->
    <tr>
      <td>v85.0.4183.133-1</td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v85.0.4183.133-1/chromium-browser-stable-85.0.4183.133-1.ppc64le.rpm">rpm</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v85.0.4183.133-1/chromium-browser-stable-85.0.4183.133-1.tar.xz">.tar.xz</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v85.0.4183.133-1/ungoogled-chromium-browser-stable-85.0.4183.133-1.ppc64le.rpm">rpm</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v85.0.4183.133-1/ungoogled-chromium-browser-stable-85.0.4183.133-1.tar.xz">.tar.xz</a></td>
    </tr>
    <tr>
      <td>v84.0.4147.89-1</td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v84.0.4147.89-1/chromium-browser-stable-84.0.4147.89-1.ppc64le.rpm">rpm</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v84.0.4147.89-1/chromium-browser-stable-84.0.4147.89-1.tar.xz">.tar.xz</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v84.0.4147.89-1/ungoogled-chromium-browser-stable-84.0.4147.89-1.ppc64le.rpm">rpm</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v84.0.4147.89-1/ungoogled-chromium-browser-stable-84.0.4147.89-1.tar.xz">.tar.xz</a></td>
    </tr>
    <tr>
      <td>v83.0.4103.116-1</td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v83.0.4103.116-1/chromium-browser-stable-83.0.4103.116-1.ppc64le.rpm">rpm</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v83.0.4103.116-1/chromium-browser-stable-83.0.4103.116-1.tar.xz">.tar.xz</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v83.0.4103.116-1/ungoogled-chromium-browser-stable-83.0.4103.116-1.ppc64le.rpm">rpm</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v83.0.4103.116-1/ungoogled-chromium-browser-stable-83.0.4103.116-1.tar.xz">.tar.xz</a></td>
    </tr>
    <tr>
      <td>v83.0.4103.97-1</td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v83.0.4103.97-1/chromium-browser-stable-83.0.4103.97-1.ppc64le.rpm">rpm</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v83.0.4103.97-1/chromium-browser-stable-83.0.4103.97-1.tar.xz">.tar.xz</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v83.0.4103.97-1/ungoogled-chromium-browser-stable-83.0.4103.97-1.ppc64le.rpm">rpm</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v83.0.4103.97-1/ungoogled-chromium-browser-stable-83.0.4103.97-1.tar.xz">.tar.xz</a></td>
    </tr>
    <tr>
      <td>v83.0.4103.61-1</td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v83.0.4103.61-1/chromium-browser-stable-83.0.4103.61-1.ppc64le.rpm">rpm</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v83.0.4103.61-1/chromium-browser-stable-83.0.4103.61-1.tar.xz">.tar.xz</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v83.0.4103.61-1/ungoogled-chromium-browser-stable-83.0.4103.61-1.ppc64le.rpm">rpm</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v83.0.4103.61-1/ungoogled-chromium-browser-stable-83.0.4103.61-1.tar.xz">.tar.xz</a></td>
    </tr>
    <tr>
      <td>v81.0.4044.138-1</td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v81.0.4044.138-1/chromium-browser-stable-81.0.4044.138-1.ppc64le.rpm">rpm</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v81.0.4044.138-1/chromium-browser-stable-81.0.4044.138-1.tar.xz">.tar.xz</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v81.0.4044.138-1/ungoogled-chromium-browser-stable-81.0.4044.138-1.ppc64le.rpm">rpm</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v81.0.4044.138-1/ungoogled-chromium-browser-stable-81.0.4044.138-1.tar.xz">.tar.xz</a></td>
    </tr>
    <tr>
      <td>v81.0.4044.129-1</td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v81.0.4044.129-1/chromium-browser-stable-81.0.4044.129-1.ppc64le.rpm">rpm</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v81.0.4044.129-1/chromium-browser-stable-81.0.4044.129-1.tar.xz">.tar.xz</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v81.0.4044.129-1/ungoogled-chromium-browser-stable-81.0.4044.129-1.ppc64le.rpm">rpm</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v81.0.4044.129-1/ungoogled-chromium-browser-stable-81.0.4044.129-1.tar.xz">.tar.xz</a></td>
    </tr>
    <tr>
      <td>v81.0.4044.122-1</td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v81.0.4044.122-1/chromium-browser-stable-81.0.4044.122-1.ppc64le.rpm">rpm</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v81.0.4044.122-1/chromium-browser-stable-81.0.4044.122-1.tar.xz">.tar.xz</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v81.0.4044.122-1/ungoogled-chromium-browser-stable-81.0.4044.122-1.ppc64le.rpm">rpm</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v81.0.4044.122-1/ungoogled-chromium-browser-stable-81.0.4044.122-1.tar.xz">.tar.xz</a></td>
    </tr>
    <tr>
      <td>v81.0.4044.113-1</td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v81.0.4044.113-1/chromium-browser-stable-81.0.4044.113-1.ppc64le.rpm">rpm</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v81.0.4044.113-1/chromium-browser-stable-81.0.4044.113-1.tar.xz">.tar.xz</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v81.0.4044.113-1/ungoogled-chromium-browser-stable-81.0.4044.113-1.ppc64le.rpm">rpm</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v81.0.4044.113-1/ungoogled-chromium-browser-stable-81.0.4044.113-1.tar.xz">.tar.xz</a></td>
    </tr>
    <tr>
      <td>v80.0.3987.163-1</td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v80.0.3987.163-1/chromium-browser-stable-80.0.3987.163-1.ppc64le.rpm">rpm</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v80.0.3987.163-1/chromium-browser-stable-80.0.3987.163-1.tar.xz">.tar.xz</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v80.0.3987.163-1/ungoogled-chromium-browser-stable-80.0.3987.163-1.ppc64le.rpm">rpm</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v80.0.3987.163-1/ungoogled-chromium-browser-stable-80.0.3987.163-1.tar.xz">.tar.xz</a></td>
    </tr>
    <tr>
      <td>v80.0.3987.162-1</td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v80.0.3987.162-1/chromium-browser-stable-80.0.3987.162-1.ppc64le.rpm">rpm</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v80.0.3987.162-1/chromium-browser-stable-80.0.3987.162-1.tar.xz">.tar.xz</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v80.0.3987.162-1/ungoogled-chromium-browser-stable-80.0.3987.162-1.ppc64le.rpm">rpm</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v80.0.3987.162-1/ungoogled-chromium-browser-stable-80.0.3987.162-1.tar.xz">.tar.xz</a></td>
    </tr>
    <tr>
      <td>v80.0.3987.149-1</td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v80.0.3987.149-1/chromium-browser-stable-80.0.3987.149-1.ppc64le.rpm">rpm</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v80.0.3987.149-1/chromium-browser-stable-80.0.3987.149-1.tar.xz">.tar.xz</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v80.0.3987.149-1/ungoogled-chromium-browser-stable-80.0.3987.149-1.ppc64le.rpm">rpm</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v80.0.3987.149-1/ungoogled-chromium-browser-stable-80.0.3987.149-1.tar.xz">.tar.xz</a></td>
    </tr>
    <tr>
      <td>v80.0.3987.132-1</td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v80.0.3987.132-1/chromium-browser-stable-80.0.3987.132-1.ppc64le.rpm">rpm</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v80.0.3987.132-1/chromium-browser-stable-80.0.3987.132-1.tar.xz">.tar.xz</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v80.0.3987.132-1/ungoogled-chromium-browser-stable-80.0.3987.132-1.ppc64le.rpm">rpm</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v80.0.3987.132-1/ungoogled-chromium-browser-stable-80.0.3987.132-1.tar.xz">.tar.xz</a></td>
    </tr>
    <tr>
      <td>v80.0.3987.122-1</td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v80.0.3987.122-1/chromium-browser-stable-80.0.3987.122-1.ppc64le.rpm">rpm</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v80.0.3987.122-1/chromium-browser-stable-80.0.3987.122-1.tar.xz">.tar.xz</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v80.0.3987.122-1/ungoogled-chromium-browser-stable-80.0.3987.122-1.ppc64le.rpm">rpm</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v80.0.3987.122-1/ungoogled-chromium-browser-stable-80.0.3987.122-1.tar.xz">.tar.xz</a></td>
    </tr>
    <tr>
      <td>v80.0.3987.116-1</td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v80.0.3987.116-1/chromium-browser-stable-80.0.3987.116-1.ppc64le.rpm">rpm</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v80.0.3987.116-1/chromium-browser-stable-80.0.3987.116-1.tar.xz">.tar.xz</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v80.0.3987.116-1/ungoogled-chromium-browser-stable-80.0.3987.116-1.ppc64le.rpm">rpm</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v80.0.3987.116-1/ungoogled-chromium-browser-stable-80.0.3987.116-1.tar.xz">.tar.xz</a></td>
    </tr>
    <tr>
      <td>v80.0.3987.100-1</td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v80.0.3987.100-1/chromium-browser-stable-80.0.3987.100-1.ppc64le.rpm">rpm</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v80.0.3987.100-1/chromium-browser-stable-80.0.3987.100-1.tar.xz">.tar.xz</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v80.0.3987.100-1/ungoogled-chromium-browser-stable-80.0.3987.100-1.ppc64le.rpm">rpm</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v80.0.3987.100-1/ungoogled-chromium-browser-stable-80.0.3987.100-1.tar.xz">.tar.xz</a></td>
    </tr>
    <tr>
      <td>v80.0.3987.87-1</td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v80.0.3987.87-1/chromium-browser-stable-80.0.3987.87-1.ppc64le.rpm">rpm</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v80.0.3987.87-1/chromium-browser-stable-80.0.3987.87-1.tar.xz">.tar.xz</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v80.0.3987.87-1/ungoogled-chromium-browser-stable-80.0.3987.87-1.ppc64le.rpm">rpm</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v80.0.3987.87-1/ungoogled-chromium-browser-stable-80.0.3987.87-1.tar.xz">.tar.xz</a></td>
    </tr>
    <tr>
      <td>v79.0.3945.130-1</td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v79.0.3945.130-1/chromium-browser-stable-79.0.3945.130-1.ppc64le.rpm">rpm</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v79.0.3945.130-1/chromium-browser-stable-79.0.3945.130-1.tar.xz">.tar.xz</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v79.0.3945.130-1/ungoogled-chromium-browser-stable-79.0.3945.130-1.ppc64le.rpm">rpm</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v79.0.3945.130-1/ungoogled-chromium-browser-stable-79.0.3945.130-1.tar.xz">.tar.xz</a></td>
    </tr>
    <tr>
      <td>v79.0.3945.117-1</td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v79.0.3945.117-1/chromium-browser-stable-79.0.3945.117-1.ppc64le.rpm">rpm</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v79.0.3945.117-1/chromium-browser-stable-79.0.3945.117-1.tar.xz">.tar.xz</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v79.0.3945.117-1/ungoogled-chromium-browser-stable-79.0.3945.117-1.ppc64le.rpm">rpm</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v79.0.3945.117-1/ungoogled-chromium-browser-stable-79.0.3945.117-1.tar.xz">.tar.xz</a></td>
    </tr>
    <tr>
      <td>v79.0.3945.88-1</td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v79.0.3945.88-1/chromium-browser-stable-79.0.3945.88-1.ppc64le.rpm">rpm</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v79.0.3945.88-1/chromium-browser-stable-79.0.3945.88-1.tar.xz">.tar.xz</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v79.0.3945.88-1/ungoogled-chromium-browser-stable-79.0.3945.88-1.ppc64le.rpm">rpm</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v79.0.3945.88-1/ungoogled-chromium-browser-stable-79.0.3945.88-1.tar.xz">.tar.xz</a></td>
    </tr>
    <tr>
      <td>v79.0.3945.79-1</td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v79.0.3945.79-1/chromium-browser-stable-79.0.3945.79-1.ppc64le.rpm">rpm</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v79.0.3945.79-1/chromium-browser-stable-79.0.3945.79-1.tar.xz">.tar.xz</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v79.0.3945.79-1/ungoogled-chromium-browser-stable-79.0.3945.79-1.ppc64le.rpm">rpm</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v79.0.3945.79-1/ungoogled-chromium-browser-stable-79.0.3945.79-1.tar.xz">.tar.xz</a></td>
    </tr>
    <tr>
      <td>v78.0.3904.108-1</td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v78.0.3904.108-1/chromium-browser-stable-78.0.3904.108-1.ppc64le.rpm">rpm</a></td>
      <td align="center"><a href="https://github.com/chromium-ppc64le/chromium-ppc64le/releases/download/v78.0.3904.108-1/chromium-browser-stable-78.0.3904.108-1.tar.xz">.tar.xz</a></td>
      <td align="center">rpm</td>
      <td align="center">.tar.xz</td>
    </tr>
  </tbody>
</table>

