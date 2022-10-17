#
# Dockerfile for shadowsocks-libev
#

FROM alpine:3.6

ARG TZ='Europe/Berlin'

ENV TZ $TZ
ENV SS_LIBEV_VERSION 3.1.0 
ENV SS_DOWNLOAD_URL https://github.com/shadowsocks/shadowsocks-libev/releases/download/v$SS_LIBEV_VERSION/shadowsocks-libev-$SS_LIBEV_VERSION.tar.gz
ENV OBFS_DOWNLOAD_URL https://github.com/shadowsocks/simple-obfs.git

RUN apk upgrade --update \
    && apk add bash tzdata libsodium \
    && apk add --virtual .build-deps \
        autoconf \
        automake \
        asciidoc \
        xmlto \
        build-base \
        curl \
        c-ares-dev \
        libev-dev \
        libtool \
        linux-headers \
        udns-dev \
        libsodium-dev \
        mbedtls-dev \
        pcre-dev \
        udns-dev \
        tar \
        git \
    && curl -sSLO ${SS_DOWNLOAD_URL} \
    && tar -zxf shadowsocks-libev-${SS_LIBEV_VERSION}.tar.gz \
    && (cd shadowsocks-libev-${SS_LIBEV_VERSION} \
    && ./configure --prefix=/usr --disable-documentation \
    && make install) \
    && git clone ${OBFS_DOWNLOAD_URL} \
    && (cd simple-obfs \
    && git submodule update --init --recursive \
    && ./autogen.sh && ./configure \
    && make && make install) \
    && ln -sf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone \
    && runDeps="$( \
        scanelf --needed --nobanner /usr/bin/ss-* /usr/local/bin/obfs-* \
            | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
            | xargs -r apk info --installed \
            | sort -u \
        )" \
    && apk add --virtual .run-deps $runDeps \
    && apk del .build-deps \
    && rm -rf shadowsocks-libev-${SS_LIBEV_VERSION}.tar.gz \
        shadowsocks-libev-${SS_LIBEV_VERSION} \
        simple-obfs \
        /var/cache/apk/*

ENV SERVER_ADDR 0.0.0.0
ENV SERVER_PORT 8388
ENV METHOD      chacha20-ietf-poly1305
ENV TIMEOUT     300
ENV DNS_ADDR    8.8.8.8
ENV DNS_ADDR_2  8.8.4.4
ENV ARGS=
ENV PASS=

EXPOSE $SERVER_PORT/tcp $SERVER_PORT/udp
CMD ss-server -s $SERVER_ADDR \
              -p $SERVER_PORT \
              -k $PASS \
              -m $METHOD \
              -t $TIMEOUT \
              --fast-open \
              -d $DNS_ADDR \
              -d $DNS_ADDR_2 \
              --plugin obfs-server --plugin-opts "obfs=tls;obfs-host=google.com" \
              -u \
              $ARGS
