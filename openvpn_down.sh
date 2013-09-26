#!/bin/bash
#############################################
source /opt/global.sh
int_ip="`ip addr show $int_iface | grep inet -m 1 | awk '{print $2}' | cut -d '/' -f1`"

#############################################
log "openvpn stopped"

#############################################
# forward
iptables -F FORWARD
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -s 10.0.0.131 -o "$int_iface" -p tcp --dport 443 -j ACCEPT
iptables -A FORWARD -s 10.0.0.131 -o "$int_iface" -p udp --dport 1194 -j ACCEPT
iptables -P FORWARD DROP

#############################################
# snat
log "restart iptables -t nat"
iptables -t nat -F
iptables -t nat -A POSTROUTING ! -s "$int_ip" -o "$int_iface" -j SNAT --to-source "$int_ip"
log "iptables-save -t nat:
`iptables-save -t nat`"

#############################################
conntrack -F >/dev/null 2>&1
