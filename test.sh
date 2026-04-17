#!/bin/sh
docker rm -f tor-gateway 2>/dev/null
docker run -d --name tor-gateway --cap-add NET_ADMIN --cap-add NET_RAW tor-gateway

echo "Waiting for Tor to bootstrap..."
until docker logs tor-gateway 2>&1 | grep -q "Bootstrapped 100%"; do sleep 2; done
echo "Tor ready."

echo "nameserver 127.0.0.1" > /tmp/resolv.conf
docker run --rm \
  --network container:tor-gateway \
  -v /tmp/resolv.conf:/etc/resolv.conf \
  curlimages/curl curl -s https://check.torproject.org/api/ip

docker rm -f tor-gateway
