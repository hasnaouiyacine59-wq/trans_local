#!/bin/sh
set -e

# Tor user UID (debian-tor = 101)
TOR_UID=$(id -u debian-tor)

iptables -t nat -F
iptables -t nat -A OUTPUT -m owner --uid-owner $TOR_UID -j RETURN
iptables -t nat -A OUTPUT -d 127.0.0.0/8 -j RETURN
# Redirect DNS
iptables -t nat -A OUTPUT -p udp --dport 53 -j REDIRECT --to-ports 5353
# Redirect TCP to TransPort
iptables -t nat -A OUTPUT -p tcp --syn -j REDIRECT --to-ports 9040

exec tor -f /etc/tor/torrc
