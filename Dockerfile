FROM ubuntu:20.04

LABEL description="Janus WebRTC by Ubuntu image" 

# timezone setting
ENV TZ=Asia/Tokyo 

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update && apt-get install -y \
    libmicrohttpd-dev \
    libjansson-dev \
	libssl-dev \
    libsofia-sip-ua-dev \
    libglib2.0-dev \
	libopus-dev \
    libogg-dev \
    libcurl4-openssl-dev \
    liblua5.3-dev \
	libconfig-dev \
    pkg-config \
    libtool \
    automake \
    wget \
    make \
    cmake \
    git \
    meson \
    ninja-build

RUN wget https://github.com/cisco/libsrtp/archive/v2.2.0.tar.gz \
    && tar xfv v2.2.0.tar.gz \
    && cd libsrtp-2.2.0 \
    && ./configure --prefix=/usr --enable-openssl \
    && make shared_library && make install \
    && cd ..

RUN git clone --depth 1 https://github.com/sctplab/usrsctp \
    && cd usrsctp \
    && ./bootstrap \
    && ./configure --prefix=/usr/lib64 --disable-programs --disable-inet --disable-inet6 \
    && make && make install \
    && cd ..

RUN git clone -b v3.2-stable https://libwebsockets.org/repo/libwebsockets \
    && cd libwebsockets \
    && mkdir build \
    && cd build \
    && cmake -DLWS_MAX_SMP=1 -DLWS_WITHOUT_EXTENSIONS=0 -DCMAKE_INSTALL_PREFIX:PATH=/usr -DCMAKE_C_FLAGS="-fpic" .. \
    && make && make install \
    && cd ../../

RUN git clone --depth 1 https://gitlab.freedesktop.org/libnice/libnice \
    && cd libnice \
    && meson --prefix=/usr --libdir=lib build && ninja -C build && ninja -C build install \
    && cd ..

RUN git clone --depth 1 https://github.com/meetecho/janus-gateway.git \
    && cd janus-gateway \
    && sh autogen.sh \
    && ./configure --prefix=/opt/janus --disable-rabbitmq --disable-mqtt \
    && make \
    && make install \
    && make configs
    
RUN sed -i s/'\tenabled = false'/'\tenabled = true'/ /opt/janus/etc/janus/janus.transport.pfunix.jcfg
RUN sed -i s/'#path = "\/path\/to\/ux-janusapi"'/'path = "\/tmp\/janus.sock"'/ /opt/janus/etc/janus/janus.transport.pfunix.jcfg
RUN sed -i s/'var server = gatewayCallbacks.server;'/'var server = \"http:\/\/\" + window.location.hostname + \":8088\/janus";'/ /opt/janus/share/janus/demos/janus.js

VOLUME [ "/opt/janus/share/janus/demos" ]

ENTRYPOINT ["/opt/janus/bin/janus"]
