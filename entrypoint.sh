#!/bin/sh
set -e

TOR_UID=$(id -u debian-tor)
IPT=$(which iptables-legacy 2>/dev/null || which iptables)

$IPT -t nat -F

# Exempt tor user
$IPT -t nat -A OUTPUT -m owner --uid-owner $TOR_UID -j RETURN
# Exempt loopback
$IPT -t nat -A OUTPUT -d 127.0.0.0/8 -j RETURN
# Redirect TCP to TransPort (DNS on port 53 handled by Tor directly)
$IPT -t nat -A OUTPUT -p tcp --syn -j REDIRECT --to-ports 9040

exec su -s /bin/sh debian-tor -c "tor -f /etc/tor/torrc"
