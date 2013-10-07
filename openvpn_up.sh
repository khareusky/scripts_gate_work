#!/bin/bash
#############################################
source global.sh
openvpn_ip="`ip addr show $openvpn_iface | grep inet -m 1 | awk '{print $2}'| cut -d '/' -f1`";

#############################################
log "openvpn has started"

#############################################
# forward
iptables -F FORWARD
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -i "$int_iface" -o "$openvpn_iface" -j ACCEPT
iptables -P FORWARD DROP

#############################################
# snat
log "restart iptables -t nat"

iptables -t nat -F
iptables -t nat -A POSTROUTING -s 10.0.0.131 -o "$openvpn_iface" -j SNAT --to-source "$openvpn_ip"

#############################################
conntrack -F >/dev/null 2>&1
