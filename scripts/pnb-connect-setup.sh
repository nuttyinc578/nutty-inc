#!/usr/bin/env bash
set -euo pipefail

# pnb connect router: route host traffic through Tor's transparent proxy
# This script sets up Tor, enables IP forwarding, and applies NAT rules so
# that all outbound traffic from the machine (or a downstream LAN) exits via Tor.
# Review carefully before running on a production system.

# Require root privileges
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" >&2
  exit 1
fi

TORRC="/etc/tor/torrc"
BACKUP_TORRC="/etc/tor/torrc.backup.pnb-connect"

# Install dependencies
if command -v apt-get >/dev/null 2>&1; then
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install -y tor iptables-persistent
else
  echo "This setup script currently supports apt-based distributions." >&2
  exit 1
fi

# Backup existing torrc if we haven't already
if [[ -f "$TORRC" && ! -f "$BACKUP_TORRC" ]]; then
  cp "$TORRC" "$BACKUP_TORRC"
fi

cat > "$TORRC" <<'TORCONF'
Log notice file /var/log/tor/notices.log
DataDirectory /var/lib/tor

# Listen for transparent proxy traffic
TransPort 0.0.0.0:9040
DNSPort 0.0.0.0:9053

# Map virtual addresses for non-exit-friendly destinations
VirtualAddrNetworkIPv4 10.192.0.0/10
AutomapHostsOnResolve 1

# Avoid using system DNS directly
DNSPort 9053
CacheDirectoryGroupReadable 1
ControlPort 9051
CookieAuthentication 1
TORCONF

systemctl restart tor
systemctl enable tor

# Enable IP forwarding
sysctl -w net.ipv4.ip_forward=1
if ! grep -q '^net.ipv4.ip_forward=1' /etc/sysctl.conf; then
  echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
fi

# Flush existing NAT rules that could conflict
iptables -t nat -F
iptables -t nat -X

# Replace eth0 with your external interface if different
EXTERNAL_IFACE=${EXTERNAL_IFACE:-eth0}
INTERNAL_IFACE=${INTERNAL_IFACE:-}

# Route DNS queries to Tor's DNSPort
iptables -t nat -A PREROUTING -i ${INTERNAL_IFACE:-$EXTERNAL_IFACE} -p udp --dport 53 -j REDIRECT --to-ports 9053

# Redirect TCP traffic to Tor's TransPort
iptables -t nat -A PREROUTING -i ${INTERNAL_IFACE:-$EXTERNAL_IFACE} -p tcp --syn -j REDIRECT --to-ports 9040

# Preserve Tor traffic and local network
iptables -t nat -A OUTPUT -m owner --uid-owner debian-tor -j RETURN
iptables -t nat -A OUTPUT -o lo -j RETURN
iptables -t nat -A OUTPUT -d 127.0.0.0/8 -j RETURN

# Redirect all other local outbound TCP to Tor
iptables -t nat -A OUTPUT -p tcp --syn -j REDIRECT --to-ports 9040

# Save rules so they persist across reboots
netfilter-persistent save

echo "pnb connect router is configured. Verify connectivity and that tor is running with: systemctl status tor"
