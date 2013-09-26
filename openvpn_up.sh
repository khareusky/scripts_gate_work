#!/bin/bash
#############################################
source /opt/global.sh
openvpn_ip="`ip addr show $openvpn_iface | grep inet -m 1 | awk '{print $2}'| cut -d '/' -f1`";

#############################################
log "openvpn has started"

#############################################
# forward
iptables -F FORWARD
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -s 10.0.0.131 -j ACCEPT
iptables -P FORWARD DROP

#############################################
# snat
log "restart iptables -t nat"

iptables -t nat -F
iptables -t nat -A POSTROUTING -s 10.0.0.131 -o "$openvpn_iface" -j SNAT --to-source "$openvpn_ip"

log "iptables-save -t nat:
`iptables-save -t nat`"

#############################################
conntrack -F >/dev/null 2>&1
