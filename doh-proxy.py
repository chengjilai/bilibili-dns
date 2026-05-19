#!/usr/bin/env python3
"""DNS-over-HTTPS proxy used by dnsmasq as upstream for bilibili domains."""

import socket
import base64
import urllib.request

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.bind(("127.0.0.1", 5353))
print("doh-proxy on 127.0.0.1:5353", flush=True)
while True:
    data, addr = sock.recvfrom(512)
    req = urllib.request.Request(
        f"https://doh.pub/dns-query?dns={base64.urlsafe_b64encode(data).decode().rstrip('=')}",
        headers={"Accept": "application/dns-message"},
    )
    try:
        with urllib.request.urlopen(req, timeout=5) as resp:
            sock.sendto(resp.read(), addr)
    except Exception:
        pass
