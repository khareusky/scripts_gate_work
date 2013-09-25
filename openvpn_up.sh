#!/bin/bash
#############################################
source /opt/global.sh
openvpn_ip="`ip addr show $openvpn_iface | grep inet -m 1 | awk '{print $2}'| cut -d '/' -f1`";

#############################################
log "openvpn has started"

#############################################
# snat
log "restart iptables -t nat"
iptables -t nat -F
iptables -t nat -A POSTROUTING ! -s "$openvpn_ip" -o "$openvpn_iface" -j SNAT --to-source "$openvpn_ip"
conntrack -F >/dev/null 2>&1
log "iptables-save -t nat:
`iptables-save -t nat`"

#############################################
# перезагрузка socks-сервера
log "restart sock-server (danted)"
/etc/init.d/danted stop >/dev/null 2>&1
ln -f -s /opt/danted/tun0.conf /etc/danted.conf
/etc/init.d/danted start >/dev/null 2>&1

#############################################
