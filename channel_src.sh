#!/bin/bash
###########################################################
# распределение хостов по каналам из ip адресов ЛВС
###########################################################
source global.sh

###########################################################
### SQUID SRC ###
# перезапись файлов ip адресов, разбитых по каналам
 output "###########################################################"
 output "rewrite squid config files"
 rm -f "$squid_first_channel_src"
 rm -f "$squid_second_channel_src"
 rm -f "$squid_third_channel_src"

 touch "$squid_first_channel_src"
 touch "$squid_second_channel_src"
 touch "$squid_third_channel_src"

# заполнение файлов
 while read $hosts_params; do
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
 done < <(cat $path/data/hosts.txt | grep -v "^#" | grep "[^[:space:]]")

# перезапуск squid для применения настроек
 output "reload squid"
 a=$(cat /var/run/squid3.pid 2>/dev/null)
 if [ "$a" == "" ]; then
 	/etc/init.d/squid3 restart >/dev/null
 else
 	/etc/init.d/squid3 reload >/dev/null
 fi

###########################################################
### SNAT ###
# очистка правил для NAT
 output "clear old rules"
 while read line; do
    ip rule del prio "$line"
 done < <( ip rule show | grep -e '^2[0-9][0-9][0-9][0-9]:' | cut -d ':' -f1)

# заполнения правил для тех, у кого NAT
 output "add new rules"
 prio=20000
 while read $hosts_params; do
	if [[ "$nat" != "1" ]]; then
		continue
	fi
	if [[ "$channel" == "*" ]]; then
		ip rule add from "$ip" table balance prio "$prio"
		let "prio = prio + 1"
	else if [[ "$channel" == "$ppp1" || "$channel" == "$ppp2" || "$channel" == "$ppp3" ]]; then
		ip rule add from "$ip" table "$channel" prio "$prio"
		let "prio = prio + 1"
	fi fi
 done < <(cat $path/data/hosts.txt | grep -v "^#" | grep "[^[:space:]]")

###########################################################
output "###########################################################"
output "new rules:
`ip rule ls | grep -e '^2[0-9][0-9][0-9][0-9]:'`"
 output "###########################################################"

###########################################################
