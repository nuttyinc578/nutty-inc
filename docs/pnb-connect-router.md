# pnb connect router (Tor-based VPN)

This guide and helper script set up **pnb connect router**, a simple VPN-style gateway that routes traffic over the Tor network using Tor's transparent proxy mode.

## What it does
- Installs Tor and configures it to listen for transparent proxy traffic on `9040` and DNS requests on `9053`.
- Enables IP forwarding so the host can act as a gateway for its own traffic or for a small LAN.
- Adds iptables NAT rules that redirect TCP and DNS traffic to Tor, while exempting Tor's own traffic.
- Saves firewall rules so they persist across reboots.

> ⚠️ Tor is not a magic anonymity tool. Traffic leaving the Tor network to clear-net sites can still be deanonymized by malicious exits or fingerprinted by misconfiguration. Use HTTPS, keep systems patched, and review the rules before deploying.

## Prerequisites
- Debian/Ubuntu-style system with `apt`.
- Root access to configure Tor, sysctl, and iptables.
- Optional: a downstream LAN interface if you want to provide Tor-backed egress for other devices.

## Quick start
1. Inspect the setup script to understand the rules it applies:
   ```bash
   less scripts/pnb-connect-setup.sh
   ```
2. Run the script as root (on a test machine first):
   ```bash
   sudo EXTERNAL_IFACE=eth0 INTERNAL_IFACE=eth1 scripts/pnb-connect-setup.sh
   ```
   - `EXTERNAL_IFACE` is the WAN-facing interface (defaults to `eth0`).
   - `INTERNAL_IFACE` is optional; set it to your LAN interface to NAT that traffic through Tor.
3. Verify Tor is healthy and that traffic egresses via Tor:
   ```bash
   systemctl status tor
   curl --socks5 localhost:9050 https://check.torproject.org/api/ip
   ```
4. (Optional) Configure DHCP on the LAN interface so downstream clients use this host as their default gateway and DNS server.

## How it works
- Tor runs in *transparent proxy* mode with `TransPort` and `DNSPort` enabled.
- `iptables` redirects TCP SYN packets and UDP/53 DNS queries to Tor's ports.
- `net.ipv4.ip_forward=1` lets the host route packets between interfaces.
- `netfilter-persistent` saves the NAT rules so they survive reboots.

## Removing the setup
If you want to revert:
```bash
sudo iptables -t nat -F
sudo iptables -t nat -X
sudo sysctl -w net.ipv4.ip_forward=0
sudo systemctl disable --now tor
```
Restore your previous `/etc/tor/torrc` from `/etc/tor/torrc.backup.pnb-connect` if needed.

## Troubleshooting tips
- Ensure the WAN interface has connectivity before applying NAT rules.
- Use `iptables -t nat -L -n -v` to confirm rules are loaded.
- Check Tor logs at `/var/log/tor/notices.log` for circuit and DNS resolution issues.
- If DNS is not resolving, confirm UDP/53 is being redirected to Tor's `9053` port.
