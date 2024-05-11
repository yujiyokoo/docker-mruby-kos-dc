FROM debian:bookworm

RUN \
  apt-get update && \
  apt-get upgrade -y && \
  apt-get install -y \
    build-essential git subversion libjpeg-dev libpng-dev curl libssl-dev \
    ruby bison wget python3 texinfo libelf-dev rake make

# TODO: convenience. Remove later
RUN apt-get install -y vim

RUN \
  mkdir -p /opt/toolchains/dc/kos

RUN git clone git://git.code.sf.net/p/cadcdev/kallistios /opt/toolchains/dc/kos

RUN cd /opt/toolchains/dc/kos/utils/dc-chain && ln -s config/config.mk.stable.sample config.mk

RUN apt-get install -y make libgmp-dev libmpfr-dev

RUN cd /opt/toolchains/dc/kos/utils/dc-chain && make all force_downloader=wget # gdb_download_type=xz

RUN cp /opt/toolchains/dc/kos/doc/environ.sh.sample /opt/toolchains/dc/kos/environ.sh

RUN /bin/bash -c "source /opt/toolchains/dc/kos/environ.sh && cd /opt/toolchains/dc/kos && make"

# get and build kos-ports
RUN git clone git://git.code.sf.net/p/cadcdev/kos-ports /opt/toolchains/dc/kos-ports

# Switching to wget. There were some issues with curl with ipv6 but may be specific to my development env.
RUN sed -i -e 's/FETCH_CMD\s*=\s*curl/#FETCH_CMD = curl/' -e 's/#FETCH_CMD\s*=\s*wget/FETCH_CMD = wget/' /opt/toolchains/dc/kos-ports/config.mk

RUN . /opt/toolchains/dc/kos/environ.sh && sh /opt/toolchains/dc/kos-ports/utils/build-all.sh

# build dcload-serial & dcload-ip
ENV KOS_BASE="/opt/toolchains/dc/kos"
RUN /bin/bash -c "source /opt/toolchains/dc/kos/environ.sh && cd /opt/toolchains/dc && git clone https://github.com/sizious/dcload-serial.git && cd /opt/toolchains/dc/dcload-serial && make install"
RUN /bin/bash -c "source /opt/toolchains/dc/kos/environ.sh && cd /opt/toolchains/dc && git clone https://github.com/sizious/dcload-ip.git && cd /opt/toolchains/dc/dcload-ip && make install"

RUN mkdir -p /usr/src

# We can use this if we want to use a specific release
# RUN cd /opt && git clone --branch=3.1.0 https://github.com/mruby/mruby.git mruby
# However, we use the latest for the moment here:
RUN cd /opt && git clone https://github.com/mruby/mruby.git mruby

RUN /bin/bash -c "source /opt/toolchains/dc/kos/environ.sh && cd /opt/mruby && make MRUBY_CONFIG=dreamcast_shelf"

# TODO: merge this with the rest of apt-get
RUN apt-get install -y genisoimage

RUN apt-get install -y gawk patch bzip2 tar make libgmp-dev libmpfr-dev libmpc-dev gettext wget libelf-dev texinfo bison flex sed git build-essential diffutils curl libjpeg-dev libpng-dev python3 pkg-config cmake libisofs-dev meson ninja-build rake
# TODO: rerunning... mv apt-get to the top, then replace the above build-all with this
RUN /bin/bash -c "source /opt/toolchains/dc/kos/environ.sh && /opt/toolchains/dc/kos-ports/utils/build-all.sh"

# mkdciso
RUN apt-get install -y git meson build-essential pkg-config libisofs-dev libstdc++-12-dev
RUN cd /opt && git clone https://gitlab.com/simulant/mkdcdisc.git mkdcdisc
RUN cd /opt/mkdcdisc && meson setup builddir && meson compile -C builddir && mkdir /opt/mkdcdisc/bin && mv /opt/mkdcdisc/builddir/mkdcdisc /opt/mkdcdisc/bin/

