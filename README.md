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
make
```

`make` runs `dns` (system-wide) and `doh` (user-level proxy). Use `make dns` or `make doh` individually if needed.

## Verify

```shell
make verify
```

## Effects

| File | Change |
|------|--------|
| `/etc/dnsmasq.d/bilibili.conf` | symlink → `dnsmasq.conf` |
| `/etc/dnsmasq.conf` | uncommented `conf-dir=/etc/dnsmasq.d/,*.conf` |
| `/etc/resolv.conf` | prepended `nameserver 127.0.0.1` |
| `/etc/NetworkManager/dispatcher.d/prepend-local-dns` | re-prepends `127.0.0.1` on NM changes |
| `~/.config/systemd/user/doh-proxy.service` | symlink → `doh-proxy.service` |

