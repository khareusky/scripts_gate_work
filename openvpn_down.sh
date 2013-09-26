#!/bin/bash
#############################################
source global.sh
int_ip="`ip addr show $int_iface | grep inet -m 1 | awk '{print $2}' | cut -d '/' -f1`"

#############################################
log "openvpn stopped"

#############################################
# snat
log "restart iptables -t nat"
iptables -t nat -F
iptables -t nat -A POSTROUTING ! -s "$int_ip" -o "$int_iface" -j SNAT --to-source "$int_ip"
conntrack -F >/dev/null 2>&1
log "iptables-save -t nat:
`iptables-save -t nat`"

#############################################
# перезагрузка socks-сервера
log "restart sock-server (danted)"
/etc/init.d/danted stop >/dev/null 2>&1
ln -f -s $path/danted/eth0.conf /etc/danted.conf
/etc/init.d/danted start >/dev/null 2>&1

#############################################
