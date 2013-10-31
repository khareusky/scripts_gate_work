#!/bin/bash
#############################################
source global.sh
openvpn_addr="`ip addr show $openvpn_iface | grep inet -m 1 | awk '{print $2}'| cut -d '/' -f1`";
log "openvpn has just connected: $*"

#############################################
# default route
log "restart default route to redirect traffic throw tun0"
#ip route del default >/dev/null
#ip route add default dev "$openvpn_iface"
#ip route flush cache

#############################################
# iptables
log "restart iptables to allow INPUT squid, socks, dns, icmp"
iptables -F INPUT_LAN
iptables -A INPUT_LAN -p udp --dport 53 -j ACCEPT # dns
iptables -A INPUT_LAN -p tcp --dport 1080 -j ACCEPT # socks
iptables -A INPUT_LAN -p tcp --dport 3128 -j ACCEPT # squid
iptables -A INPUT_LAN -p icmp -j ACCEPT # icmp

#############################################
# nat
log "restart nat to redirect traffic throw tun0"
iptables -F FORWARD
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -i "$int_iface" -o "$openvpn_iface" -j ACCEPT
iptables -P FORWARD DROP
iptables -t nat -F
iptables -t nat -A POSTROUTING ! -s "$openvpn_addr" -o "$openvpn_iface" -j SNAT --to-source "$openvpn_addr"

#############################################
# dns
log "restart dns to connect throw tun0"
/etc/init.d/bind9 restart

#############################################
# socks
log "restart socks to connect throw tun0"
/etc/init.d/danted stop
ln -f -s $path/dante/dante_tun0.conf /etc/danted.conf
/etc/init.d/danted start

#############################################
# squid
log "start squid to connect throw tun0"
/etc/init.d/squid3 start

#############################################
# очистка сессий
log "flush connection sessions"
conntrack -F >/dev/null 2>&1

#############################################
