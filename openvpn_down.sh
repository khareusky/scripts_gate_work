#!/bin/bash
#############################################
source global.sh
int_ip="`ip addr show $int_iface | grep inet -m 1 | awk '{print $2}' | cut -d '/' -f1`"

#############################################
log "openvpn stopped"

#############################################
# forward
log "restart iptables FORWARD"
iptables -F FORWARD
iptables -P FORWARD DROP

#############################################
# snat
log "restart iptables -t nat POSTROUTING"
iptables -t nat -F

#############################################
conntrack -F >/dev/null 2>&1
