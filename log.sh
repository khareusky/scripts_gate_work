#!/bin/bash
#################################################################
#
# - принудительная корректировка MSS в пакетах всего транзитного траффика
# - протоколирование транзитного траффика с ЛВС в сеть Интернет (NAT)
#
#################################################################
### MTU ###
 iptables -t mangle -F FORWARD
 iptables -t mangle -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

############################################################
### LOG ###
 iptables -t mangle -N FORWARD_LOG
 iptables -t mangle -F FORWARD_LOG
 iptables -t mangle -A FORWARD -m state --state NEW -j FORWARD_LOG
 while read name server passwd ip iface proxy nat pptp channel rate1 rate2 log comment
 do
 	if [[ "$log" == "1" && "$nat" == "1" ]]; then
 		iptables -t mangle -A FORWARD_LOG -s $ip -j ULOG --ulog-cprange 40
 	fi
 done < <(cat /etc/gate/data/chap-secrets | grep -v "^#" | grep "[^[:space:]]")

############################################################
 iptables-save