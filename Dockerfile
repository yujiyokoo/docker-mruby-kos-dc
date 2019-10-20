FROM debian:jessie

RUN \
  apt-get update && \
  apt-get upgrade -y && \
  apt-get install -y \
    build-essential git subversion libjpeg-dev libpng12-dev curl libssl-dev \
    ruby bison wget python texinfo

RUN \
  mkdir -p /opt/toolchains/dc/kos

RUN git clone git://git.code.sf.net/p/cadcdev/kallistios /opt/toolchains/dc/kos

RUN cd /opt/toolchains/dc/kos/utils/dc-chain && ./download.sh

RUN cd /opt/toolchains/dc/kos/utils/dc-chain && ./unpack.sh

RUN cd /opt/toolchains/dc/kos/utils/dc-chain && make

RUN cp /opt/toolchains/dc/kos/doc/environ.sh.sample /opt/toolchains/dc/kos/environ.sh

# TODO: convenience. Remove later
RUN apt-get install -y vim

# Copy and patch
COPY patch.on.kos-a449e93c615ba2d8c2abf9f4dcc485b6d7d1bfa3 /tmp/
RUN cd /opt/toolchains/dc/kos && patch -p1 < /tmp/patch.on.kos-a449e93c615ba2d8c2abf9f4dcc485b6d7d1bfa3

# Add un.h
COPY un.h /tmp/
RUN cp /tmp/un.h /opt/toolchains/dc/kos/include/sys/un.h

# build KOS
RUN . /opt/toolchains/dc/kos/environ.sh && cd /opt/toolchains/dc/kos && make

# get and build kos-ports
RUN git clone git://git.code.sf.net/p/cadcdev/kos-ports /opt/toolchains/dc/kos-ports

# Switching to wget. There were some issues with curl with ipv6 but may be specific to my development env.
RUN sed -i -e 's/FETCH_CMD\s*=\s*curl/#FETCH_CMD = curl/' -e 's/#FETCH_CMD\s*=\s*wget/FETCH_CMD = wget/' /opt/toolchains/dc/kos-ports/config.mk

RUN . /opt/toolchains/dc/kos/environ.sh && sh /opt/toolchains/dc/kos-ports/utils/build-all.sh

# install libelf TODO: move to apt-get
RUN apt-get install -y libelf-dev

# build dcload-serial & dcload-ip
RUN cd /opt/toolchains/dc && git clone https://github.com/sizious/dcload-serial.git && cd /opt/toolchains/dc/dcload-serial && make install
RUN cd /opt/toolchains/dc && git clone https://github.com/sizious/dcload-ip.git && cd /opt/toolchains/dc/dcload-ip && make install

RUN mkdir -p /usr/src

RUN cd /usr/src && git clone https://github.com/mruby/mruby.git mruby-host && cd /usr/src/mruby-host # && git checkout 7c91efc

RUN cp -R /usr/src/mruby-host /usr/src/mruby-sh4

RUN cd /usr/src/mruby-host && make

COPY envset.crosscompile.sh4.sh /vagrant/src/mruby-sh4/envset.crosscompile.sh4.sh

COPY patch.on.mruby-2.0.1.37bc343e0ad6b837de672c8c0cf6bf00876f746b /tmp/patch.on.mruby-2.0.1.37bc343e0ad6b837de672c8c0cf6bf00876f746b

RUN cd /usr/src/mruby-sh4 && patch -p1 < /tmp/patch.on.mruby-2.0.1.37bc343e0ad6b837de672c8c0cf6bf00876f746b

RUN cd /usr/src/mruby-sh4 && . /opt/toolchains/dc/kos/environ.sh && . /vagrant/src/mruby-sh4/envset.crosscompile.sh4.sh && make 2>&1 | grep 'mrbc: Syntax error: word unexpected (expecting ")"' && cp /usr/src/mruby-host/build/host/bin/mrbc build/host/bin/mrbc && make

