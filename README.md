# bilibili-dns

Bypass SJTU DNS blocking for bilibili via DNS-over-HTTPS.

## Dependencies

- `python3`
- `dnsmasq`
- `systemd`

## How it works

```
Browser → glibc → /etc/resolv.conf → 127.0.0.1:53 (dnsmasq)
  ├── *.bilibili.com   → 127.0.0.1:5353 (doh-proxy.py) → https://doh.pub/dns-query
  ├── *.bilivideo.com  → 127.0.0.1:5353                 → https://doh.pub/dns-query
  ├── *.hdslb.com      → 127.0.0.1:5353                 → https://doh.pub/dns-query
  └── *                → school DNS (202.120.2.101)
```

## Setup

```shell
git clone git@github.com:chengjilai/bilibili-dns.git
cd bilibili-dns

# 1. Link dnsmasq drop-in config (sudo)
sudo ln -rsf dnsmasq.conf /etc/dnsmasq.d/bilibili.conf

# 2. Enable conf-dir in /etc/dnsmasq.conf (sudo)
sudo sed -i 's|^#conf-dir=/etc/dnsmasq.d/,\*\.conf|conf-dir=/etc/dnsmasq.d/,*.conf|' /etc/dnsmasq.conf

# 3. Prepend 127.0.0.1 to /etc/resolv.conf and persist across NM changes (sudo)
sudo sed -i '1inameserver 127.0.0.1' /etc/resolv.conf
sudo tee /etc/NetworkManager/dispatcher.d/prepend-local-dns <<'EOF'
#!/bin/bash
if [ "$2" = "up" ] || [ "$2" = "dhcp4-change" ] || [ "$2" = "dhcp6-change" ]; then
    sed -i '/^nameserver 127\.0\.0\.1/d' /etc/resolv.conf
    sed -i '1i\nameserver 127.0.0.1' /etc/resolv.conf
fi
EOF
sudo chmod +x /etc/NetworkManager/dispatcher.d/prepend-local-dns

# 4. Restart services (sudo)
sudo systemctl enable --now dnsmasq
sudo systemctl restart dnsmasq

# 5. Install and start the DoH proxy (as user)
ln -rsf doh-proxy.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now doh-proxy
```

## Verify

```shell
getent hosts bilibili.com api.live.bilibili.com cn-sh-fx-01-01.bilivideo.com i2.hdslb.com
```

## Effects

| File | Change |
|------|--------|
| `/etc/dnsmasq.d/bilibili.conf` | symlink → `dnsmasq.conf` |
| `/etc/dnsmasq.conf` | uncommented `conf-dir=/etc/dnsmasq.d/,*.conf` |
| `/etc/resolv.conf` | prepended `nameserver 127.0.0.1` |
| `/etc/NetworkManager/dispatcher.d/prepend-local-dns` | re-prepends `127.0.0.1` on NM changes |
| `~/.config/systemd/user/doh-proxy.service` | symlink → `doh-proxy.service` |

