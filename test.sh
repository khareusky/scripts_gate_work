#!/bin/bash

source /etc/gate/global.sh


### SQUID DST ###
 rm -f "/etc/gate/data/squid3_forth_channel_dst.txt"
 touch "/etc/gate/data/squid3_forth_channel_dst.txt"

 while read site channel temp; do
    host "$site" | grep has | awk '{print $4}' >> "/etc/gate/data/squid3_forth_channel_dst.txt"
 done < <(cat /etc/gate/data/channel_dst_sites.txt | grep -v "^#" | grep "[^[:space:]]")

 a=$(cat /var/run/squid3.pid 2>/dev/null)
 if [ "$a" == "" ]; then
 	/etc/init.d/squid3 start
 else
 	/etc/init.d/squid3 reload
 fi
exit 0;
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
	done < <(cat /etc/gate/data/channel_dst_sites.txt | grep -v "^#" | grep "[^[:space:]]")
exit 0;

PPP_IFACE="ppp103"
PPP_LOCAL="193.34.34.34"
 while read temp; do
    ip rule del prio "`echo -n $PPP_IFACE | tail -c 3`"
 done < <(ip rule ls | grep ^"`echo -n $PPP_IFACE | tail -c 3`:")
 ip rule add from "$PPP_LOCAL" table "$PPP_IFACE" prio "`echo -n $PPP_IFACE | tail -c 3`"

exit 0;
while read temp; do
 ip rule del prio "`echo -n ppp103 | tail -c 3`"
done < <(ip rule ls | grep ^"`echo -n ppp103 | tail -c 3`:")