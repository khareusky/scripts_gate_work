#!/bin/bash
#############################################
source global.sh
log "openvpn stopped"

#############################################
# iptables
log "iptables restart to drop all"
iptables -F INPUT_LAN

iptables -F FORWARD
iptables -P FORWARD DROP

iptables -t nat -F

#############################################
# dns сервер
log "restart dns server to forward"
restart_dns $path/bind/named.conf.options_forward

#############################################
# очистка сессий
log "flush connection sessions"
conntrack -F >/dev/null 2>&1
