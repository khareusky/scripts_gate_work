#!/bin/bash
#############################################################
# Данный скрипт запускается при отключении одного из PPPoE каналов для доступа в сеть Интернет.
#############################################################
source /etc/gate/global.sh

if [[ "$PPP_IFACE" == "$ppp1" || "$PPP_IFACE" == "$ppp2" || "$PPP_IFACE" == "$ppp3" ]]; then
	### LOG ###
	echo "`date +%D\ %T` $0: DISCONNECT PPPoE ($PPP_IFACE | $PPP_LOCAL)" >> "$log_file"

	### SNAT: Удаление: для подмены исходного ip адреса пакетов на ip адрес сетевого интерфейса для проброса из ЛВС в сеть Интернет ###
	iptables -t nat -D POSTROUTING ! -s "$PPP_LOCAL" -o "$PPP_IFACE" -j SNAT --to-source "$PPP_LOCAL"

	### DNAT ###
	while read dport1 ip_dst dport2 temp ; do
		### DNAT: Удаление: для подмены ip адреса назначения пакетов на ip адрес требуемого компьютера для проброса из сети Интернет в ЛВС ###
		iptables -t nat -D PREROUTING -i "$PPP_IFACE" -p tcp -m tcp --dport "$dport1" -j DNAT --to-destination "$ip_dst":"$dport2" 
		
		### DNAT: Удаление: маркировка пакетов по каналам, чтобы ответные пакеты на запросы в ЛВС уходили в теже каналы ###
		iptables -t mangle -D PREROUTING -i "$PPP_IFACE" -p tcp --dport "$dport1" -m state --state NEW -j CONNMARK --set-mark 0x`echo -n "$PPP_IFACE" | tail -c 1`
	done < <(cat /etc/gate/data/list_dnat.txt | grep -v "^#" | grep "[^[:space:]]")
	
	### ROUTE ###
	/etc/gate/route/route_pppoe_down.sh
	
	### Сбросить кеш таблиц маршрутизации отключившегося канала
	conntrack -D -q $PPP_LOCAL
	
	### DNS ###
	if [ "$PPP_IFACE" == "$ppp2" ] ; then
		cp -f /etc/bind/named.conf.options_byfly /etc/bind/named.conf.options
		/etc/init.d/bind9 restart
	fi
else
	### LOG ###
	echo "`date +%D\ %T` $0: DISCONNECT PPTP ($PPP_IFACE | $PPP_REMOTE | $PPP_IPPARAM | $PEERNAME)" >> "$log_file"

	### CHECK ###
	rm /var/run/pptpd-users/$PEERNAME
fi
##########################################