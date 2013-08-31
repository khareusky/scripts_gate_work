#!/bin/bash
#############################################################
# Запускается при отключении одного из PPPoE каналов для доступа в сеть Интернет.

ppp1=ppp101
ppp2=ppp102
ppp3=ppp103

#############################################################
if [[ "$PPP_IFACE" == "$ppp1" || "$PPP_IFACE" == "$ppp2" || "$PPP_IFACE" == "$ppp3" ]]; then
	### LOG ###
	echo "`date +%D\ %T` DISCONNECT PPPoE ($0 | $PPP_IFACE | $PPP_LOCAL)" >> /mnt/sdb1/logs/ppp.log

	### Удаление: чтобы ответ пришедшего запроса извне ушел по тому же интерфейсу ###
	ip rule del from $PPP_LOCAL table $PPP_IFACE prio 10"`echo $PPP_IFACE | cut -d '0' -f2`"

	### SNAT: Удаление: для подмены исходного ip адреса пакетов на ip адрес сетевого интерфейса для проброса из ЛВС в сеть Интернет ###
	iptables -t nat -D POSTROUTING ! -s "$PPP_LOCAL" -o "$PPP_IFACE" -j SNAT --to-source "$PPP_LOCAL"

	while read ip_dst dport1 dport2 temp ; do
		### DNAT: Удаление: для подмены ip адреса назначения пакетов на ip адрес требуемого компьютера для проброса из сети Интернет в ЛВС ###
		iptables -t nat -D PREROUTING -i "$PPP_IFACE" -p tcp -m tcp --dport "$dport1" -j DNAT --to-destination "$ip_dst":"$dport2" 
		
		### DNAT: Удаление: маркировка пакетов по каналам, чтобы ответные пакеты на запросы в ЛВС уходили в теже каналы ###
		iptables -t mangle -D PREROUTING -i "$PPP_IFACE" -p tcp --dport "$dport1" -m state --state NEW -j CONNMARK --set-mark 0x`echo -n "$PPP_IFACE" | tail -c 1`
	done < <(cat /etc/gate/data/list_of_dnat.txt | grep -v "^#" | grep "[^[:space:]]")
	
	### ROUTE ###
	/etc/gate/route/route_pppoe_down.sh
	
	### DNS ###
	if [ "$PPP_IFACE" == "$ppp2" ] ; then
		cp -f /etc/bind/named.conf.options_byfly /etc/bind/named.conf.options
		/etc/init.d/bind9 restart
	fi
else
	### LOG ###
	echo "`date +%D\ %T` DISCONNECT PPTP ($0 | $PPP_IFACE | $PPP_REMOTE | $PPP_IPPARAM | $PEERNAME)" >> /mnt/sdb1/logs/ppp.log

	### CHECK ###
	rm /var/run/pptpd-users/$PEERNAME
fi
##########################################