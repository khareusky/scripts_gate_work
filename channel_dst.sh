#!/bin/bash
###########################################################
# распределение по каналам исходя из ip адресов назначения
source global.sh
squid_first_channel_dst="$path/etc/squid3/squid3_first_channel_dst.txt"
squid_second_channel_dst="$path/etc/squid3/squid3_second_channel_dst.txt"
squid_third_channel_dst="$path/etc/squid3/squid3_third_channel_dst.txt"
config="$path/data/channel_dst.txt"
log "begin"

###########################################################
### SQUID ###
log "rewrite squid config files"
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
done < <(cat "$config" | grep -v "^#" | grep "[^[:space:]]")

# перезапуск squid для применения новых настроек
log "reload squid"
a=$(cat /var/run/squid3.pid 2>/dev/null)
if [ "$a" == "" ]; then
	/etc/init.d/squid3 start >/dev/null
else
	/etc/init.d/squid3 reload >/dev/null
fi

###########################################################
### NAT ###
# удаление всех старых правил
log "clear old rules"
while read line; do
	ip rule del prio "$line"
done < <( ip rule show | grep -e '^1[0-9][0-9][0-9][0-9]:' | cut -d ':' -f1)

# заполнение новыми правилами
log "add new rules"
prio=10000
while read ip channel temp; do
	if [[ "$channel" == "$ppp1" || "$channel" == "$ppp2" || "$channel" == "$ppp3" ]]; then
		ip rule add to "$ip" table "$channel" prio "$prio"
		let "prio = prio + 1"
	fi
done < <(cat "$config" | grep -v "^#" | grep "[^[:space:]]")

###########################################################
log "\n`ip rule ls | grep -e '^1[0-9][0-9][0-9][0-9]:'`"
log "end"
