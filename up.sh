#!/bin/bash
#############################################
source /etc/openvpn/global.sh
log "openvpn started"

ip_tun0="`ip addr show tun0|grep inet -m 1| awk '{print $2}'| cut -d '/' -f1`";
iptables -t nat -F
iptables -t nat -A POSTROUTING ! -s "$ip_tun0" -o tun0 -j SNAT --to-source "$ip_tun0"
conntrack -F >/dev/null 2>&1

/etc/init.d/danted stop >/dev/null 2>&1
ln -f -s /etc/danted_tun0.conf /etc/danted.conf
/etc/init.d/danted start >/dev/null 2>&1

#############################################
