FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    tor iptables \
 && rm -rf /var/lib/apt/lists/* \
 && usermod -u 9001 debian-tor

COPY torrc /etc/tor/torrc
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 9040/tcp 5353/udp

ENTRYPOINT ["/entrypoint.sh"]
