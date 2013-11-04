#!/bin/bash
#############################################
source global.sh
openvpn_addr="`ip addr show $openvpn_iface | grep inet -m 1 | awk '{print $2}'| cut -d '/' -f1`"
openvpn_lan="`ip addr show $openvpn_iface | grep inet -m 1 | awk '{print $2}' | head -c -4 | cut -d . -f 1-3`.0/24"
log "openvpn has just connected"

#############################################
# default route
log "restart route to redirect traffic throw $openvpn_iface"
ip route flush table main
ip route add "$int_lan" dev "$int_iface"
ip route add "$openvpn_lan" dev "$openvpn_iface"
ip route add default dev "$openvpn_iface"
ip route flush cache

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
log "restart nat to redirect traffic throw $openvpn_iface"
iptables -F FORWARD
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -i "$int_iface" -o "$openvpn_iface" -j ACCEPT
iptables -P FORWARD DROP
iptables -t nat -F
iptables -t nat -A POSTROUTING ! -s "$openvpn_addr" -o "$openvpn_iface" -j SNAT --to-source "$openvpn_addr"

#############################################
# dns
log "restart dns to connect throw $openvpn_iface"
/etc/init.d/bind9 restart

#############################################
# socks
log "restart socks to connect throw $openvpn_iface"
/etc/init.d/danted stop
ln -f -s $path/dante/dante_tun0.conf /etc/danted.conf
/etc/init.d/danted start

#############################################
# squid
log "start squid to connect throw $openvpn_iface"
/etc/init.d/squid3 start

#############################################
