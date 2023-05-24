# SPDX-FileCopyrightText: 2021-2023, Carles Fernandez-Prades <carles.fernandez@cttc.es>
# SPDX-License-Identifier: MIT

FROM ubuntu:18.04

LABEL version="3.0" description="Geniux builder" maintainer="carles.fernandez@cttc.es"

# build with "docker build --build-arg PETA_VERSION=2021.2 --build-arg PETA_RUN_FILE=petalinux-v2021.2-final-installer.run -t docker_petalinux2:2021.2 ."
# or "docker build --build-arg PETA_VERSION=2021.2 --build-arg PETA_RUN_FILE=petalinux-v2021.2-final-installer.run --build-arg VIVADO_INSTALLER=Xilinx_Unified_2021.2_1021_0703.tar.gz -t docker_petalinux2:2021.2 ."

# Install dependencies
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y -q \
  autoconf \
  bc \
  bison \
  build-essential \
  ca-certificates \
  chrpath \
  cpio \
  curl \
  dbus \
  dbus-x11 \
  debianutils \
  diffstat \
  expect \
  flex \
  fonts-droid-fallback \
  fonts-ubuntu-font-family-console \
  gawk \
  gcc-multilib \
  git \
  gnupg \
  gtk2-engines \
  gzip \
  iproute2 \
  iputils-ping \
  kmod \
  lib32z1-dev \
  libcanberra-gtk-module \
  libegl1-mesa \
  libglib2.0-dev \
  libgtk2.0-0 \
  libjpeg62-dev \
  libpython3.8-dev \
  libncurses5-dev \
  libsdl1.2-dev \
  libselinux1 \
  libssl-dev \
  libswt-gtk-4-jni \
  libtool \
  libtool-bin \
  locales \
  lsb-release \
  lxappearance \
  nano \
  net-tools \
  pax \
  pylint3 \
  python \
  python3 \
  python3-pexpect \
  python3-pip \
  python3-git \
  python3-jinja2 \
  rsync \
  screen \
  socat \
  sudo \
  texinfo \
  tftpd \
  tofrodos \
  ttf-ubuntu-font-family \
  u-boot-tools \
  ubuntu-gnome-default-settings \
  unzip \
  update-inetd \
  wget \
  xorg \
  xterm \
  xvfb \
  xxd \
  zlib1g-dev \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN dpkg --add-architecture i386 && apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y -q \
  zlib1g:i386 libc6-dev:i386 \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8 && update-locale

# make a petalinux user
RUN adduser --disabled-password --gecos '' petalinux && \
  usermod -aG sudo petalinux && \
  echo "petalinux ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Install the repo tool to handle git submodules (meta layers) comfortably.
ADD https://storage.googleapis.com/git-repo-downloads/repo /usr/local/bin/
RUN chmod 777 /usr/local/bin/repo

ARG PETA_VERSION
ARG PETA_RUN_FILE

# The HTTP server to retrieve the files from.
ARG HTTP_SERV=http://172.17.0.1:8000/installers

COPY accept-eula.sh /
COPY y2k22_patch-1.2.zip /

# run the Petalinux installer
RUN cd / && wget -q ${HTTP_SERV}/${PETA_RUN_FILE} && \
  chmod a+rx /${PETA_RUN_FILE} && \
  chmod a+rx /accept-eula.sh && \
  mkdir -p /opt/Xilinx && \
  chmod 777 /tmp /opt/Xilinx && \
  cd /tmp && \
  sudo -u petalinux -i /accept-eula.sh /${PETA_RUN_FILE} /opt/Xilinx/petalinux && \
  rm -f /${PETA_RUN_FILE} /accept-eula.sh

ARG VIVADO_INSTALLER
ARG VIVADO_AGREE="XilinxEULA,3rdPartyEULA"
ARG VIVADO_UPDATE

COPY install_config.txt /vivado-config/

RUN \
  if [ "$VIVADO_INSTALLER" ] ; then \
  mkdir -p /vivado-installer && cd /vivado-installer/ && wget -q ${HTTP_SERV}/${VIVADO_INSTALLER} && cd .. && \
  cat /vivado-installer/${VIVADO_INSTALLER} | tar zx --strip-components=1 -C /vivado-installer && \
  cp /vivado-config/install_config.txt /vivado-installer/ && \
  /vivado-installer/xsetup \
  --agree ${VIVADO_AGREE} \
  --batch Install \
  --config /vivado-installer/install_config.txt && \
  rm -rf /vivado-installer ; \
  fi

# apply 2021.2.1 Update
RUN \
  if [ "$VIVADO_UPDATE" ] ; then \
  mkdir -p /vivado-installer && cd /vivado-installer/ && wget -q ${HTTP_SERV}/${VIVADO_UPDATE} && cd .. && \
  cat /vivado-installer/${VIVADO_UPDATE} | tar zx --strip-components=1 -C /vivado-installer && \
  cp /vivado-config/install_config.txt /vivado-installer/ && \
  /vivado-installer/xsetup \
  --agree ${VIVADO_AGREE} \
  --batch Update \
  --config /vivado-installer/install_config.txt && \
  rm -rf /vivado-installer ; \
  fi

# apply Vitis patch
RUN \
  if [ "$VIVADO_UPDATE" ] ; then \
  mv /y2k22_patch-1.2.zip /tools/Xilinx/ && cd /tools/Xilinx/ && unzip y2k22_patch-1.2.zip && \
  export LD_LIBRARY_PATH=$PWD/Vivado/2021.2/tps/lnx64/python-3.8.3/lib/ && \
  ./Vivado/2021.2/tps/lnx64/python-3.8.3/bin/python3 y2k22_patch/patch.py && \
  rm y2k22_patch-1.2.zip && rm -rf y2k22_patch ; \
  fi

# make /bin/sh symlink to bash instead of dash:
RUN echo "dash dash/sh boolean false" | debconf-set-selections
RUN DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash

# not really necessary, just to make it easier to install packages on the run...
RUN echo "root:petalinux" | chpasswd

USER petalinux
ENV HOME /home/petalinux
ENV LANG en_US.UTF-8
RUN mkdir /home/petalinux/project
WORKDIR /home/petalinux/project
ENV SHELL /bin/bash

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

RUN git config --global user.email "geniux@example.com" && git config --global user.name "Geniux"

ENTRYPOINT ["/bin/bash", "-l"]
