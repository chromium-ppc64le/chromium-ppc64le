# Copyright 2019 Colin Samples
#
# SPDX-License-Identifier: Apache-2.0
#

FROM quay.io/centos/centos:centos8

RUN dnf -y install epel-release && \
    dnf -y install dnf-plugins-core && \
    dnf config-manager --set-enabled powertools && \
    dnf config-manager --set-enabled devel
RUN dnf -y update && \
    dnf -y install \
        alsa-lib-devel \
        atk-devel \
        bison \
        ccache \
        clang \
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
        libstdc++-static \
        libva-devel \
        make \
        mesa-libgbm-devel \
        meson \
        ninja-build \
        nodejs \
        nss-devel \
        pango-devel \
        patch \
        pciutils-devel \
        pulseaudio-libs-devel \
        python2 \
        quilt \
        rpm-build \
        wget \
        xcb-proto \
        libdrm-devel \
        libXtst-devel \
        xz \
    && dnf clean all

# hack to chromium still uses python 2.7...
RUN cp -r /usr/lib/python3.6/site-packages/xcbgen /usr/lib/python2.7/site-packages
RUN ln -s /usr/bin/python2.7 /usr/bin/python

COPY libgnome-keyring-3.12.0-15.el8.ppc64le.rpm /tmp
COPY libgnome-keyring-devel-3.12.0-15.el8.ppc64le.rpm /tmp
RUN rpm -i /tmp/libgnome-keyring-3.12.0-15.el8.ppc64le.rpm
RUN rpm -i /tmp/libgnome-keyring-devel-3.12.0-15.el8.ppc64le.rpm

RUN mkdir -p /workdir
WORKDIR /workdir

CMD ["/usr/bin/make", "-w", "-j16"]
