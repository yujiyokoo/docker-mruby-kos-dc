FROM debian:stretch

RUN \
  apt-get update && \
  apt-get upgrade -y && \
  apt-get install -y \
    build-essential git subversion libjpeg-dev libpng-dev curl libssl-dev \
    ruby bison wget python texinfo libelf-dev rake

# TODO: convenience. Remove later
RUN apt-get install -y vim

RUN \
  mkdir -p /opt/toolchains/dc/kos

RUN git clone git://git.code.sf.net/p/cadcdev/kallistios /opt/toolchains/dc/kos

RUN cd /opt/toolchains/dc/kos/utils/dc-chain && ln -s config.mk.stable.sample config.mk

RUN cd /opt/toolchains/dc/kos/utils/dc-chain && ./download.sh

RUN cd /opt/toolchains/dc/kos/utils/dc-chain && ./unpack.sh

# FIXME: aarch64 systems has problems with config.guess from 2011. Overwriting gcc-4.7.4/config.guess with a newer version
RUN cp /opt/toolchains/dc/kos/utils/dc-chain/config.guess /opt/toolchains/dc/kos/utils/dc-chain/gcc-4.7.4/config.guess

RUN cd /opt/toolchains/dc/kos/utils/dc-chain && make

RUN cp /opt/toolchains/dc/kos/doc/environ.sh.sample /opt/toolchains/dc/kos/environ.sh

RUN . /opt/toolchains/dc/kos/environ.sh && cd /opt/toolchains/dc/kos && make

# get and build kos-ports
RUN git clone git://git.code.sf.net/p/cadcdev/kos-ports /opt/toolchains/dc/kos-ports

# Switching to wget. There were some issues with curl with ipv6 but may be specific to my development env.
RUN sed -i -e 's/FETCH_CMD\s*=\s*curl/#FETCH_CMD = curl/' -e 's/#FETCH_CMD\s*=\s*wget/FETCH_CMD = wget/' /opt/toolchains/dc/kos-ports/config.mk

RUN . /opt/toolchains/dc/kos/environ.sh && sh /opt/toolchains/dc/kos-ports/utils/build-all.sh

# build dcload-serial & dcload-ip
# FIXME: Currently there's a problem with latest dcload-ip. Using an older version for now.
ENV KOS_BASE="/opt/toolchains/dc/kos"
RUN cd /opt/toolchains/dc && git clone https://github.com/sizious/dcload-serial.git && cd /opt/toolchains/dc/dcload-serial && make install
RUN cd /opt/toolchains/dc && git clone https://github.com/sizious/dcload-ip.git && cd /opt/toolchains/dc/dcload-ip && git checkout 45d586187806 && git reset --hard && make install

RUN mkdir -p /usr/src

# We can use this if we want to use a specific release
# RUN cd /opt && git clone --branch=3.1.0 https://github.com/mruby/mruby.git mruby
# However, we use the latest for the moment here:
RUN cd /opt && git clone https://github.com/mruby/mruby.git mruby

RUN cd /opt/mruby && make MRUBY_CONFIG=dreamcast_shelf
