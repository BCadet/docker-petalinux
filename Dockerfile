ARG UBUNTU_VERSION=20.04
FROM ubuntu:${UBUNTU_VERSION} as docker-petalinux

LABEL maintainer "BCadet <https://github.com/BCadet>"

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y -q \
    gosu

ADD https://gist.githubusercontent.com/BCadet/372702916a20b141cb78ea889e3dae59/raw/73822ba555bfbd75ab7c09c90d463585535e5a0e/container-entrypoint /container-entrypoint
RUN chmod +x /container-entrypoint
ENTRYPOINT [ "/container-entrypoint" ]

# create user
RUN useradd --create-home builder

#install dependences:
RUN dpkg --add-architecture i386 &&\
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y -q \
    build-essential \
    tofrodos \
    iproute2 \
    gawk \
    net-tools \
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
    u-boot-tools \
    wget \
    libx11-xcb-dev \
    libasound-dev net-tools \
    software-properties-common \
    apt-transport-https \
    zlib1g \
    zlib1g-dev \
    zlib1g:i386 \
    bc \
    python \
    && rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8 && update-locale

FROM docker-petalinux as petalinux-install-stage

ARG PETA_RUN_FILE=petalinux-v2021.2-final-installer.run

SHELL [ "/bin/bash", "-c" ]

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    expect

# run the install
COPY ./petalinux-* /

ADD https://gist.githubusercontent.com/BCadet/ae21e861e55740ed0c47a33e7215817e/raw/deb9128476ca3677a67cf5f7e75024147bae86e8/petalinux-accept-eula.sh /petalinux-accept-eula.sh

RUN chmod a+rx /petalinux-* && \
    mkdir -p /opt/Xilinx && \
    chmod 777 /tmp /opt/Xilinx

USER builder
WORKDIR /tmp

RUN PETALINUX_INSTALLER=$(ls / | grep petalinux-v[0-9.]*-final-installer.run) && \
    if [ $(echo "${PETALINUX_INSTALLER:11:6} >= 2020.1" | bc -l) -eq 1 ]; \
    then /petalinux-accept-eula.sh /${PETALINUX_INSTALLER} "-d /opt/Xilinx/petalinux" ; \
    else /petalinux-accept-eula.sh /${PETALINUX_INSTALLER} "/opt/Xilinx/petalinux" ; \
    fi

FROM docker-petalinux

COPY --from=petalinux-install-stage /opt/Xilinx /opt/Xilinx

# make /bin/sh symlink to bash instead of dash:
RUN echo "dash dash/sh boolean false" | debconf-set-selections
RUN DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash

ENV LANG en_US.UTF-8
#add tools to path
RUN echo "source /opt/Xilinx/petalinux/settings.sh" >> /home/builder/.bashrc

