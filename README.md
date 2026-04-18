# trans_local

A real transparent Tor gateway using Docker. All TCP traffic from any container sharing the network namespace is routed through Tor automatically — no proxy configuration needed in the client.

## Architecture

```
Container B (Camoufox / any app)
  ↓  raw TCP — no proxy config
Shared network namespace
  ↓
iptables OUTPUT REDIRECT → port 9040
  ↓
Tor TransPort (transparent proxy)
  ↓
Tor network (anonymized)
```

DNS is handled by Tor's `DNSPort` on port 53 — no DNS leaks.

## Files

| File | Description |
|------|-------------|
| `Dockerfile` | Container A — Tor gateway (tor + iptables) |
| `torrc` | Tor config: TransPort 9040, DNSPort 53, AutomapHostsOnResolve |
| `entrypoint.sh` | Sets iptables rules, runs Tor as `debian-tor` (UID 9001) |
| `Dockerfile.test` | Container B — Camoufox anti-detect browser for testing |
| `b_cum.py` | Test script: visits `check.torproject.org/api/ip` via Camoufox |
| `test.sh` | Full test runner: starts gateway, waits for bootstrap, runs B |
| `requirements.txt` | Python deps for Container B |

## How it works

### Container A — Tor Gateway

- Runs `tor` as user `debian-tor` (UID 9001)
- On startup, `entrypoint.sh` sets two iptables rules:
  - **Exempt UID 9001** — Tor's own traffic bypasses the redirect (prevents loop)
  - **Exempt loopback** — `127.0.0.0/8` bypasses redirect
  - **Redirect all TCP** → `TransPort 9040`
- Tor's `DNSPort` listens on `0.0.0.0:53` — handles all DNS resolution through Tor
- Uses `iptables-legacy` backend for compatibility

### Container B — Client

- Runs with `--network container:tor-gateway` to share Container A's network namespace
- Has **zero proxy configuration** — traffic is intercepted transparently by iptables
- Uses Camoufox (Firefox fork with C++-level fingerprint spoofing) to browse

## Quick Start

### Build

```bash
docker build -t tor-gateway .
docker build -f Dockerfile.test -t camoufox-test .
```

### Run

```bash
bash test.sh
```

Or manually:

```bash
# Start gateway
docker run -d --name tor-gateway --cap-add NET_ADMIN --cap-add NET_RAW tor-gateway

# Wait for Tor bootstrap
until docker logs tor-gateway 2>&1 | grep -q "Bootstrapped 100%"; do sleep 2; done

# Run client (shares gateway network namespace)
docker run --rm \
  --network container:tor-gateway \
  -v "$HOME/.cache/camoufox:/root/.cache/camoufox:ro" \
  camoufox-test

docker rm -f tor-gateway
```

### Expected output

```json
{"IsTor":true,"IP":"192.42.116.48"}
```

## Requirements

- Docker with `NET_ADMIN` + `NET_RAW` capabilities (for iptables inside container)
- Camoufox binaries pre-fetched on host: `pip install camoufox && python -m camoufox fetch`

## Key design decisions

- **`debian-tor` remapped to UID 9001** — avoids collision with `curlimages/curl` and other images that use UID 100, which would accidentally match the iptables exemption rule and bypass Tor
- **`iptables-legacy`** — the nf_tables backend doesn't intercept packets from shared-namespace containers on kernel 5.4
- **`DNSPort 0.0.0.0:53`** — Tor listens directly on port 53, no redirect needed for DNS, no DNS leaks
- **`--network container:X`** — shares the full network namespace (interfaces, iptables, routing) between containers
