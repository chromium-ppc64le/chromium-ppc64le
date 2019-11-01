# Copyright 2019 Colin Samples
#
# SPDX-License-Identifier: Apache-2.0
#

FROM fedora:30

RUN dnf -y update && dnf clean all

RUN dnf -y install git wget make cmake ninja-build clang python \
    libstdc++-static xz patch findutils cups-devel nss-devel glib2-devel \
    libgnome-keyring-devel pango-devel dbus-devel atk-devel gtk3-devel \
    libva-devel nodejs gperf pulseaudio-libs-devel java-1.8.0-openjdk \
    pciutils-devel alsa-lib-devel bison libXScrnSaver-devel elfutils \
    fakeroot rpm-build quilt meson \
    && dnf clean all

RUN mkdir -p /workdir
WORKDIR /workdir

COPY docker-root /workdir

CMD ["/usr/bin/make", "-w", "-j16"]

