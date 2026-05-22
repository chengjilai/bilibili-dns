.ONESHELL:
.PHONY: install dns doh uninstall verify

install: dns doh

dns:
	sudo ln -rsf dnsmasq.conf /etc/dnsmasq.d/bilibili.conf
	sudo sed -i 's|^#conf-dir=/etc/dnsmasq.d/,\*\.conf|conf-dir=/etc/dnsmasq.d/,*.conf|' /etc/dnsmasq.conf
	sudo sed -i '1inameserver 127.0.0.1' /etc/resolv.conf
	sudo tee /etc/NetworkManager/dispatcher.d/prepend-local-dns >/dev/null <<-'EOF'
	#!/bin/bash
	if [ "$$2" = "up" ] || [ "$$2" = "dhcp4-change" ] || [ "$$2" = "dhcp6-change" ]; then
		sed -i '/^nameserver 127\.0\.0\.1/d' /etc/resolv.conf
		sed -i '1inameserver 127.0.0.1' /etc/resolv.conf
	fi
	EOF
	sudo chmod +x /etc/NetworkManager/dispatcher.d/prepend-local-dns
	sudo systemctl enable --now dnsmasq
	sudo systemctl restart dnsmasq

doh:
	ln -rsf doh-proxy.service ~/.config/systemd/user/
	systemctl --user daemon-reload
	systemctl --user enable --now doh-proxy

uninstall:
	sudo rm -f /etc/dnsmasq.d/bilibili.conf /etc/NetworkManager/dispatcher.d/prepend-local-dns
	sudo sed -i '/^nameserver 127\.0\.0\.1/d' /etc/resolv.conf
	sudo systemctl disable --now dnsmasq 2>/dev/null; true
	systemctl --user disable --now doh-proxy 2>/dev/null; true
	rm -f ~/.config/systemd/user/doh-proxy.service

verify:
	getent hosts bilibili.com api.live.bilibili.com cn-sh-fx-01-01.bilivideo.com i2.hdslb.com
