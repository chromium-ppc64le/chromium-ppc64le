# Copyright 2019 Colin Samples
#
# SPDX-License-Identifier: Apache-2.0
#

FROM fedora:30

RUN dnf -y update && \
    dnf -y install \
        alsa-lib-devel \
        atk-devel \
        bison \
        ccache \
        clang \
        cmake \
        createrepo_c \
        cups-devel \
        dbus-devel \
        elfutils \
        fakeroot \
        findutils \
        git \
        glib2-devel \
        gperf \
        gtk3-devel \
        java-1.8.0-openjdk \
        libXScrnSaver-devel \
        libgnome-keyring-devel \
        libstdc++-static \
        libva-devel \
        make \
        meson \
        ninja-build \
        nodejs \
        nss-devel \
        pango-devel \
        patch \
        pciutils-devel \
        pulseaudio-libs-devel \
        python \
        quilt \
        rpm-build \
        wget \
        xz \
    && dnf clean all

RUN mkdir -p /workdir
WORKDIR /workdir

CMD ["/usr/bin/make", "-w", "-j16"]

