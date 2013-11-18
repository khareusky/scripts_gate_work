#!/bin/bash
#############################################################
# Данный скрипт запускается при подключении одного из PPPoE каналов для доступа в сеть Интернет.
#############################################################
source global.sh

### LOG ###
echo "`date +%D\ %T` $0: CONNECT $PPP_IFACE: local ip = $PPP_LOCAL; remote ip = $PPP_REMOTE; dns1 = $DNS1; dns2 = $DNS2;" >> "$log_file"

### ROUTE ###
$path/route_ppp_up.sh

### SNAT: Добавление: для подмены исходного ip адреса пакетов на ip адрес сетевого интерфейса при пробросе из ЛВС в сеть Интернет ###
iptables -t nat -A POSTROUTING ! -s "$PPP_LOCAL" -o "$PPP_IFACE" -j SNAT --to-source "$PPP_LOCAL"

### RATE ###
$path/rate/pppoe.sh

### Перенаправление сайтов на заданые каналы ###
prio=900
while read line; do
    ip rule del prio "$line"
done < <( ip rule show | grep -e '^9[0-9][0-9]:' | cut -d ':' -f1)

while read site channel; do
	while read line; do
		ip rule add to "$line" table temp97 prio "$prio"
		let "prio = prio + 1"
	done < <(host "$site" | grep has | awk '{print $4}')
done < <(cat $path/data/channel_dst_sites.txt | grep -v "^#" | grep "[^[:space:]]")

##########################################
