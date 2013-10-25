#!/bin/bash
#############################################
source global.sh
openvpn_addr="`ip addr show $openvpn_iface | grep inet -m 1 | awk '{print $2}'| cut -d '/' -f1`";
log "openvpn has started"

#############################################
# iptables
log "restart iptables to allow"
iptables -F INPUT_LAN
iptables -A INPUT_LAN -p udp --dport 53 -j ACCEPT
iptables -A INPUT_LAN -p icmp -j ACCEPT

iptables -F FORWARD
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -i "$int_iface" -o "$openvpn_iface" -j ACCEPT
iptables -P FORWARD DROP

iptables -t nat -F
iptables -t nat -A POSTROUTING ! -s "$openvpn_addr" -o "$openvpn_iface" -j SNAT --to-source "$openvpn_addr"

#############################################
# dns сервер
log "restart dns server to root servers"
restart_dns $path/bind/named.conf.options_root

#############################################
# очистка сессий
log "flush connection sessions"
conntrack -F >/dev/null 2>&1
