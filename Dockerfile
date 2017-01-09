FROM debian:stretch-slim
Maintainer Stephen Price <stephen@stp5.net>

RUN export DEBIAN_FRONTEND='noninteractive' && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
      curl \
      transmission-remote-cli \
      $(apt-get -s dist-upgrade|awk '/^Inst.*ecurity/ {print $2}') && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/*

ENV VPNUSER user
ENV VPNPASS password
ENV TRANSMISSION_HOST transmission
ENV TRANSMISSION_PORT 9091

ENTRYPOINT ["/bin/bash"]
