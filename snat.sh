#!/bin/bash
###########################################################
# Цикл по записи хостов в цепочку FORWARD_SNAT
###########################################################
source /etc/gate/global.sh

###########################################################
### FILTER FORWARD_SNAT ###
 iptables -F FORWARD_SNAT
 while read name server passwd ip iface proxy nat temp; do
    if [ "$nat" == "1" ]; then ### предоставление доступа перехода пакетов между сетевыми интерфейсами для проброса из ЛВС в сеть Интернет ###
        iptables -A FORWARD_SNAT -s "$ip" -j ACCEPT
    fi
 done < <(cat /etc/gate/data/hosts.txt | grep -v "^#" | grep "[^[:space:]]")

###########################################################
### SQUID ###
#перезапись файлов ip адресов, разбитых по каналам
 rm -f "$squid_first_channel_src"
 rm -f "$squid_second_channel_src"
 rm -f "$squid_third_channel_src"

 touch "$squid_first_channel_src"
 touch "$squid_second_channel_src"
 touch "$squid_third_channel_src"

# заполнение файлов
 while read name server passwd ip iface proxy nat pptp channel temp; do
	if [[ "$proxy" != "1" ]]; then
	    continue
	fi
	if [[ "$channel" == "$ppp1" ]]; then
		echo $ip >> "$squid_first_channel_src"
	else if [[ "$channel" == "$ppp2" ]]; then
		echo $ip >> "$squid_second_channel_src"
	else if [[ "$channel" == "$ppp3" ]]; then
		echo $ip >> "$squid_third_channel_src"
	fi fi fi
 done < <(cat /etc/gate/data/hosts.txt | grep -v "^#" | grep "[^[:space:]]")

# перезапуск squid для применения настроек
 a=$(cat /var/run/squid3.pid 2>/dev/null)
 if [ "$a" == "" ]; then
 	/etc/init.d/squid3 start
 else
 	/etc/init.d/squid3 reload
 fi

###########################################################
### SNAT ###
# очистка правил для NAT
 while read line; do
    ip rule del prio "$line"
 done < <( ip rule show | grep -e '^2[0-9][0-9][0-9][0-9]:' | cut -d ':' -f1)

# заполнения правил для тех, у кого NAT
 prio=20000
 while read name server passwd ip iface proxy nat pptp channel temp; do
	if [[ "$nat" != "1" ]]; then
		continue
	fi
	if [[ "$channel" == "$ppp1" || "$channel" == "$ppp2" || "$channel" == "$ppp3" ]]; then
		ip rule add from "$ip" table "$channel" prio "$prio"
		let "prio = prio + 1"
	fi
 done < <(cat /etc/gate/data/hosts.txt | grep -v "^#" | grep "[^[:space:]]")

###########################################################