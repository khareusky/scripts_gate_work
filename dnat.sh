#!/bin/bash
###########################################################
# Цикл по записи хостов в цепочку PREROUTING_DNAT таблицы nat и таблицы mangle
###########################################################
source global.sh

fill() {
	while read dport1 ip_dst dport2 temp; do
		### DNAT: Добавление: для подмены ip адреса назначения пакетов на ip адрес требуемого компьютера при пробросе из сети Интернет в ЛВС ###
		iptables -t nat -A PREROUTING_DNAT -i "$1" -p tcp -m tcp --dport "$dport1" -j DNAT --to-destination "$ip_dst":"$dport2"
		
		### DNAT: Добавление: маркировка пакетов по каналам, чтобы ответные пакеты на запросы в ЛВС уходили в теже каналы ###
		iptables -t mangle -A PREROUTING_DNAT -i "$1" -p tcp --dport "$dport1" -m state --state NEW -j CONNMARK --set-mark 0x`echo -n "$1" | tail -c 1`
	done < <(cat $path/data/list_dnat.txt | grep -v "^#" | grep "[^[:space:]]")
}

iptables -t nat -F PREROUTING_DNAT
iptables -t mangle -F PREROUTING_DNAT
iptables -F FORWARD_DNAT
while read dport1 ip_dst dport2 temp; do
    iptables -A FORWARD_DNAT -o "$int" -d "$ip_dst" -p tcp --dport "$dport2" -j ACCEPT
    iptables -A FORWARD_DNAT -i "$int" -s "$ip_dst" -p tcp --sport "$dport2" -j ACCEPT
done < <(cat $path/data/list_dnat.txt | grep -v "^#" | grep "[^[:space:]]")
fill "$ppp1"
fill "$ppp2"
fill "$ppp3"

###########################################################