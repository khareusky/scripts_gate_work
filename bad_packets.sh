#!/bin/bash
###########################################################
source global.sh
chain_name="BAD_PACKETS"

###########################################################
# очистка и заполнение
iptables -F "$chain_name"
iptables -A "$chain_name" -p tcp --tcp-flags SYN,ACK SYN,ACK -m state --state NEW -j REJECT --reject-with tcp-reset
iptables -A "$chain_name" -p tcp ! --syn -m state --state NEW -j DROP

###########################################################
# вывод
log "\n`iptables-save -t filter | grep $chain_name`"

###########################################################
