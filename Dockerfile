FROM alpine:edge
MAINTAINER Stephen Price <stephen@stp5.net>

RUN apk add --no-cache --update \
      bash \
      curl \
      transmission-cli

ENV TRANSMISSION_HOST transmission
ENV TRANSMISSION_PORT 9091

COPY pia-update-port.sh /

VOLUME /data

CMD ["/pia-update-port.sh"]
