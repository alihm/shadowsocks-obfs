#
# Dockerfile for shadowsocks-libev
#

FROM ubuntu

ARG SS_VER=3.1.1

ENV SERVER_ADDR 0.0.0.0
ENV SERVER_PORT 8388
ENV PASSWORD    WomenLifeFreedom
ENV METHOD      chacha20-ietf-poly1305
ENV TIMEOUT     300
ENV DNS_ADDR    8.8.8.8
ENV DNS_ADDR_2  8.8.4.4
ENV ARGS=

RUN apt install shadowsocks-libev simple-obfs nginx -y
USER nobody
EXPOSE $SERVER_PORT/tcp $SERVER_PORT/udp
CMD ss-server -s $SERVER_ADDR \
              -p $SERVER_PORT \
              -k ${PASSWORD:-$(hostname)} \
              -m $METHOD \
              -t $TIMEOUT \
              --fast-open \
              -d $DNS_ADDR \
              -d $DNS_ADDR_2 \
              --plugin obfs-server --plugin-opts "obfs=http" \
              -u \
              $ARGS
