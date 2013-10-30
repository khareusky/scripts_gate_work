#!/bin/bash
#############################################
source global.sh

# route
log "remove default route"
ip route del default >/dev/null
ip route flush cache

# iptables
log "restart iptables to drop all"
iptables -F INPUT_LAN

# nat
log "stop nat"
iptables -F FORWARD
iptables -P FORWARD DROP
iptables -t nat -F

# dns сервер
log "stop dns"
/etc/init.d/bind9 stop >/dev/null 2>&1

# socks server
log "stop socks"
/etc/init.d/danted stop >/dev/null 2>&1

# proxy
log "stop squid"
/etc/init.d/squid3 restart >/dev/null 2>&1


# очистка сессий
log "flush connection sessions"
conntrack -F >/dev/null 2>&1

