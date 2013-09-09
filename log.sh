#!/bin/bash
#################################################################
# Протоколирование транзитного траффика с ЛВС в сеть Интернет (NAT)
#################################################################

# заполнение пользовательской цепочки хостами ЛВС
 iptables -t mangle -F FORWARD_LOG
 while read name server passwd ip iface proxy nat pptp channel rate1 rate2 log temp; do
 	if [[ "$log" == "1" && "$nat" == "1" ]]; then
 		iptables -t mangle -A FORWARD_LOG -s "$ip" -j ULOG --ulog-cprange 40
 	fi
 done < <(cat /etc/gate/data/hosts.txt | grep -v "^#" | grep "[^[:space:]]")

############################################################
