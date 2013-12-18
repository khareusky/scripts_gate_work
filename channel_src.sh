#!/bin/bash
###########################################################
# распределение хостов по каналам из ip адресов ЛВС
source global.sh
squid_first_channel_src="$path/etc/squid3/squid3_first_channel_src.txt"
squid_second_channel_src="$path/etc/squid3/squid3_second_channel_src.txt"
squid_third_channel_src="$path/etc/squid3/squid3_third_channel_src.txt"
log "begin"

###########################################################
### SQUID SRC ###
# перезапись файлов ip адресов, разбитых по каналам
log "rewrite squid config files"
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
done < <(cat $hosts_file | grep -v "^#" | grep "[^[:space:]]")

# перезапуск squid для применения настроек
log "reload squid"
a=$(cat /var/run/squid3.pid 2>/dev/null)
if [ "$a" == "" ]; then
	/etc/init.d/squid3 restart >/dev/null
else
	/etc/init.d/squid3 reload >/dev/null
fi

###########################################################
### SNAT ###
ip rule add to 10.0.0.0/24 table main prio 20

# очистка правил для NAT
log "clear old rules"
while read line; do
	ip rule del prio "$line"
done < <( ip rule show | grep -e '^2[0-9][0-9][0-9][0-9]:' | cut -d ':' -f1)

# заполнения правил для тех, у кого NAT
log "add new rules"
prio=20000
while read $hosts_params; do
	if [[ "$nat" != "1" ]]; then
		continue
	fi
	if [[ "$channel" == "*" ]]; then
		ip rule add from "$ip" table balance prio "$prio"
	else if [[ "$channel" == "$ppp1" || "$channel" == "$ppp2" || "$channel" == "$ppp3" ]]; then
		ip rule add from "$ip" table "$channel" prio "$prio"
	fi fi
	let "prio = prio + 1"
done < <(cat $hosts_file | grep -v "^#" | grep "[^[:space:]]")

###########################################################
log "\n`ip rule ls | grep -e '^2[0-9][0-9][0-9][0-9]:'`"
log "end"
