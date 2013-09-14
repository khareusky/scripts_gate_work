#!/bin/bash
###########################################################
# распределение по каналам исходя из ip адресов назначения
###########################################################
source /etc/gate/global.sh
filename="/etc/gate/data/channel_dst.txt"

###########################################################
### SQUID ###
 output "rewrite squid config files"
 rm -f "$squid_first_channel_dst"
 rm -f "$squid_second_channel_dst"
 rm -f "$squid_third_channel_dst"

 touch "$squid_first_channel_dst"
 touch "$squid_second_channel_dst"
 touch "$squid_third_channel_dst"

 while read ip channel temp; do
	if [[ "$channel" == "$ppp1" ]]; then
		echo $ip >> "$squid_first_channel_dst"
	else if [[ "$channel" == "$ppp2" ]]; then
		echo $ip >> "$squid_second_channel_dst"
	else if [[ "$channel" == "$ppp3" ]]; then
		echo $ip >> "$squid_third_channel_dst"
	fi fi fi
 done < <(cat "$filename" | grep -v "^#" | grep "[^[:space:]]")

# перезапуск squid для применения новых настроек
 output "reload squid"
 a=$(cat /var/run/squid3.pid 2>/dev/null)
 if [ "$a" == "" ]; then
 	/etc/init.d/squid3 start
 else
 	/etc/init.d/squid3 reload
 fi

###########################################################
### NAT ###
# удаление всех старых правил
 output "clear old rules"
 while read line; do
    ip rule del prio "$line"
 done < <( ip rule show | grep -e '^1[0-9][0-9][0-9][0-9]:' | cut -d ':' -f1)

# заполнение новыми правилами
 output "add new rules"
 prio=10000
 while read ip channel temp; do
	if [[ "$channel" == "$ppp1" || "$channel" == "$ppp2" || "$channel" == "$ppp3" ]]; then
		ip rule add to "$ip" table "$channel" prio "$prio"
		let "prio = prio + 1"
 	fi
 done < <(cat "$filename" | grep -v "^#" | grep "[^[:space:]]")

###########################################################
output "new rules:"
output "`ip rule ls | grep -e '^1[0-9][0-9][0-9][0-9]:'`"
