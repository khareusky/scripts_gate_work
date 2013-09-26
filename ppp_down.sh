#!/bin/bash
#############################################################
# Данный скрипт запускается при отключении одного из PPPoE каналов для доступа в сеть Интернет.
#############################################################
source global.sh

if [[ "$PPP_IFACE" == "$ppp1" || "$PPP_IFACE" == "$ppp2" || "$PPP_IFACE" == "$ppp3" ]]; then
	### LOG ###
	echo "`date +%D\ %T` $0: DISCONNECT PPPoE ($PPP_IFACE | $PPP_LOCAL)" >> "$log_file"

	### ROUTE ###
	$path/route_ppp_down.sh

	### SNAT: Удаление: для подмены исходного ip адреса пакетов на ip адрес сетевого интерфейса для проброса из ЛВС в сеть Интернет ###
	iptables -t nat -D POSTROUTING ! -s "$PPP_LOCAL" -o "$PPP_IFACE" -j SNAT --to-source "$PPP_LOCAL"
	
	### Сбросить кеш таблиц маршрутизации отключившегося канала
	conntrack -D -q "$PPP_LOCAL"

	### Перезапуск DNS ###
	# удаление старых правил по перенаправлению dns серверов отключившегося провайдера через его канал
	ip rule del prio 1"`echo -n $PPP_IFACE | tail -c 1`"0
	ip rule del prio 1"`echo -n $PPP_IFACE | tail -c 1`"1

	# замена конф файла и перезапуск локального dns сервера
	if [[ "$PPP_IFACE" == "$ppp2" ]]; then
		if [[ "`ip addr show $ppp1 | grep inet -m 1 | awk '{print $2}'| cut -d '/' -f1`" != "" ]] ; then
			cp -f /etc/bind/named.conf.options_"$ppp1" /etc/bind/named.conf.options
		else if [[ "`ip addr show $ppp3 | grep inet -m 1 | awk '{print $2}'| cut -d '/' -f1`" != "" ]]; then
			cp -f /etc/bind/named.conf.options_"$ppp3" /etc/bind/named.conf.options
		fi fi
		chown bind:bind /etc/bind/named.conf.options
		/etc/init.d/bind9 restart
	fi
else
	### LOG ###
	echo "`date +%D\ %T` $0: DISCONNECT PPTP ($PPP_IFACE | $PPP_REMOTE | $PPP_IPPARAM | $PEERNAME)" >> "$log_file"

	### CHECK ###
	rm /var/run/pptpd-users/$PEERNAME
fi

##########################################
