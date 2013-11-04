#!/bin/bash
#############################################
source global.sh

#############################################
# route
log "restart default route to redirect traffic throw $redirect_ip"
ip route flush table main
ip route add "$int_lan" dev "$int_iface"
ip route add default via "$redirect_ip"
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
log "restart nat to redirect traffic throw $redirect_ip"
iptables -F FORWARD
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -i "$int_iface" -o "$int_iface" -j ACCEPT
iptables -P FORWARD DROP
iptables -t nat -F

#############################################
# dns сервер
log "restart dns"
/etc/init.d/bind9 restart >/dev/null 2>&1

#############################################
# socks server
log "restart socks"
/etc/init.d/danted stop >/dev/null 2>&1
ln -f -s $path/dante/dante_eth0.conf /etc/danted.conf
/etc/init.d/danted start >/dev/null 2>&1

#############################################
# proxy
log "restart squid"
/etc/init.d/squid3 start >/dev/null 2>&1

#############################################
# очистка сессий
log "flush connection sessions"
conntrack -F >/dev/null 2>&1

#############################################
