#!/bin/bash
#################################################################
# Заполнение пользовательской цепочки FORWARD_LOG хостами ЛВС для протоколирования
#################################################################

 iptables -t mangle -F FORWARD_LOG # очистка цепочки
 while read name server passwd ip iface proxy nat pptp channel rate1 rate2 log temp; do
 	if [[ "$log" == "1" && "$nat" == "1" ]]; then
 		iptables -t mangle -A FORWARD_LOG -s "$ip" -j ULOG --ulog-cprange 40
 	fi
 done < <(cat /etc/gate/data/hosts.txt | grep -v "^#" | grep "[^[:space:]]")

############################################################
