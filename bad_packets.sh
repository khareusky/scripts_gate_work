#!/bin/bash
###########################################################
source global.sh
chain_name="BAD_PACKETS"
log "begin"

###########################################################
# очистка и заполнение
iptables -F "$chain_name"
iptables -A "$chain_name" -m state --state INVALID -j DROP
iptables -A "$chain_name" -p tcp --tcp-flags SYN,ACK SYN,ACK -m state --state NEW -j DROP
iptables -A "$chain_name" -p tcp ! --syn -m state --state NEW -j DROP # Syn-flood protection
iptables -A "$chain_name" -p tcp --tcp-flags ALL ALL -j DROP # XMAS packets
iptables -A "$chain_name" -p tcp --tcp-flags ALL NONE -j DROP # Drop all NULL packets
iptables -A "$chain_name" -f -j DROP # Force Fragments packets check

iptables -A "$chain_name" -p tcp --tcp-flags ACK,FIN FIN -j DROP # drop common attacks, port scan
iptables -A "$chain_name" -p tcp --tcp-flags ACK,PSH PSH -j DROP
iptables -A "$chain_name" -p tcp --tcp-flags ACK,URG URG -j DROP
iptables -A "$chain_name" -p tcp --tcp-flags FIN,RST FIN,RST -j DROP
iptables -A "$chain_name" -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP
iptables -A "$chain_name" -p tcp --tcp-flags SYN,RST SYN,RST -j DROP
iptables -A "$chain_name" -p tcp --tcp-flags ALL ALL -j DROP
iptables -A "$chain_name" -p tcp --tcp-flags ALL NONE -j DROP
iptables -A "$chain_name" -p tcp --tcp-flags ALL FIN,PSH,URG -j DROP
iptables -A "$chain_name" -p tcp --tcp-flags ALL SYN,FIN,PSH,URG -j DROP
iptables -A "$chain_name" -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP

###########################################################
log "\n`iptables-save -t filter | grep $chain_name`"
log "end"
