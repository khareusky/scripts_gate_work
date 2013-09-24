#!/bin/bash
#############################################
source /etc/openvpn/scripts/global.sh
ip_eth0="10.0.0.131";

log "openvpn stopped"
iptables -t nat -F
iptables -t nat -A POSTROUTING ! -s "$ip_eth0" -o eth0 -j SNAT --to-source "$ip_eth0"
conntrack -F >/dev/null 2>&1

/etc/init.d/danted stop >/dev/null 2>&1
ln -f -s /etc/danted_eth0.conf /etc/danted.conf
/etc/init.d/danted start >/dev/null 2>&1

#############################################
