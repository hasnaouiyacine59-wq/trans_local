#!/bin/sh
docker rm -f tor-gateway 2>/dev/null
docker run -d --name tor-gateway --cap-add NET_ADMIN --cap-add NET_RAW tor-gateway

echo "Waiting for Tor to bootstrap..."
until docker logs tor-gateway 2>&1 | grep -q "Bootstrapped 100%"; do sleep 2; done
echo "Tor ready."

docker build -q -f Dockerfile.test -t camoufox-test .
docker run --rm \
  --network container:tor-gateway \
  -v "$HOME/.cache/camoufox:/root/.cache/camoufox:ro" \
  camoufox-test

docker rm -f tor-gateway
