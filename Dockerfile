# SPDX-FileCopyrightText: 2021, Carles Fernandez-Prades <carles.fernandez@cttc.es>
# SPDX-License-Identifier: MIT

FROM ubuntu:18.04

MAINTAINER Carles Fernandez-Prades <carles.fernandez@cttc.es>

# build with "docker build --build-arg PETA_VERSION=2020.2 --build-arg PETA_RUN_FILE=petalinux-v2020.2-final-installer.run -t docker_petalinux2:2020.2 ."
# or "docker build --build-arg PETA_VERSION=2020.1 --build-arg PETA_RUN_FILE=petalinux-v2020.1-final-installer.run --build-arg VIVADO_INSTALLER=Xilinx_Unified_2020.1_0602_1208.tar.gz -t docker_petalinux2:2020.1 ."

# install dependences:

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y -q \
  build-essential \
  sudo \
  tofrodos \
  iproute2 \
  gawk \
  net-tools \
  expect \
  libncurses5-dev \
  tftpd \
  update-inetd \
  libssl-dev \
  flex \
  bison \
  libselinux1 \
  gnupg \
  wget \
  socat \
  gcc-multilib \
  libsdl1.2-dev \
  libglib2.0-dev \
  lib32z1-dev \
  libgtk2.0-0 \
  screen \
  pax \
  diffstat \
  xvfb \
  xterm \
  texinfo \
  gzip \
  unzip \
  cpio \
  chrpath \
  autoconf \
  lsb-release \
  libtool \
  libtool-bin \
  locales \
  kmod \
  git \
  rsync \
  bc \
  u-boot-tools \
  python \
  xxd \
  repo \
  nano \
  libjpeg62-dev \
  lxappearance \
  fonts-droid-fallback \
  ttf-ubuntu-font-family \
  fonts-ubuntu-font-family-console \
  ca-certificates \
  curl \
  xorg \
  dbus \
  dbus-x11 \
  ubuntu-gnome-default-settings \
  gtk2-engines \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN dpkg --add-architecture i386 && apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y -q \
  zlib1g:i386 libc6-dev:i386 \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

ARG PETA_VERSION
ARG PETA_RUN_FILE

RUN locale-gen en_US.UTF-8 && update-locale

# make a petalinux user
RUN adduser --disabled-password --gecos '' petalinux && \
  usermod -aG sudo petalinux && \
  echo "petalinux ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

COPY accept-eula.sh ${PETA_RUN_FILE} /

# run the install
RUN chmod a+rx /${PETA_RUN_FILE} && \
  chmod a+rx /accept-eula.sh && \
  mkdir -p /opt/Xilinx && \
  chmod 777 /tmp /opt/Xilinx && \
  cd /tmp && \
  sudo -u petalinux -i /accept-eula.sh /${PETA_RUN_FILE} /opt/Xilinx/petalinux && \
  rm -f /${PETA_RUN_FILE} /accept-eula.sh

ARG VIVADO_INSTALLER

COPY install_config.txt /vivado-installer/
COPY Xilinx_Unified_${PETA_VERSION}_*.tar.gz /vivado-installer/

RUN \
  if [ "$VIVADO_INSTALLER" ] ; then \
    cat /vivado-installer/${VIVADO_INSTALLER} | tar zx --strip-components=1 -C /vivado-installer && \
    /vivado-installer/xsetup \
      --agree 3rdPartyEULA,WebTalkTerms,XilinxEULA \
      --batch Install \
      --config /vivado-installer/install_config.txt && \
    rm -rf /vivado-installer ; \
  fi

# make /bin/sh symlink to bash instead of dash:
RUN echo "dash dash/sh boolean false" | debconf-set-selections
RUN DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash

USER petalinux
ENV HOME /home/petalinux
ENV LANG en_US.UTF-8
RUN mkdir /home/petalinux/project
WORKDIR /home/petalinux/project

# add petalinux tools to path

# Source settings at login
USER root

RUN echo "/usr/sbin/in.tftpd --foreground --listen --address [::]:69 --secure /tftpboot" >> /etc/profile && \
  echo ". /opt/Xilinx/petalinux/settings.sh" >> /etc/profile && \
  if [ "$VIVADO_INSTALLER" ] ; then \
    echo ". /tools/Xilinx/Vivado/${PETA_VERSION}/settings64.sh" >> /etc/profile ; \
  fi && \
  echo ". /etc/profile" >> /root/.profile

EXPOSE 69/udp

USER petalinux

ENTRYPOINT ["/bin/sh", "-l"]
