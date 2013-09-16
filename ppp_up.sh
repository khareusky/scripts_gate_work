#!/bin/bash
#############################################################
# Данный скрипт запускается при подключении одного из PPPoE каналов для доступа в сеть Интернет.
#############################################################
source /etc/gate/global.sh

if [[ "$PPP_IFACE" == "$ppp1" || "$PPP_IFACE" == "$ppp2" || "$PPP_IFACE" == "$ppp3" ]]; then # если канал является интернетовским
	### LOG ###
	echo "`date +%D\ %T` $0: CONNECT $PPP_IFACE: local ip = $PPP_LOCAL; remote ip = $PPP_REMOTE; dns1 = $DNS1; dns2 = $DNS2;" >> "$log_file"

	### CHANNEL DST ###
	#/etc/gate/channel/dst.sh auto

	### ROUTE ###
	/etc/gate/route_ppp_up.sh

	### SNAT: Добавление: для подмены исходного ip адреса пакетов на ip адрес сетевого интерфейса при пробросе из ЛВС в сеть Интернет ###
	iptables -t nat -A POSTROUTING ! -s "$PPP_LOCAL" -o "$PPP_IFACE" -j SNAT --to-source "$PPP_LOCAL"

	### RATE ###
	/etc/gate/rate/pppoe.sh

	### Перезапуск DNS ###
	# перезапись данных по перенаправлению на dns сервера подключившегося провайдера через его канал
	ip rule del prio 1"`echo -n $PPP_IFACE | tail -c 1`"0
	ip rule del prio 1"`echo -n $PPP_IFACE | tail -c 1`"1
	ip rule add to "$DNS1" table "$PPP_IFACE" prio 1"`echo -n $PPP_IFACE | tail -c 1`"0
	ip rule add to "$DNS2" table "$PPP_IFACE" prio 1"`echo -n $PPP_IFACE | tail -c 1`"1

	# сохранение данных dns серверов провайдера
	echo "# Данный файл изменяется скриптом /etc/gate/ppp_up.sh при подключении к каналам
# $PPP_IFACE
options {
	directory \"/var/cache/bind\";
	forwarders {
		$DNS1;
		$DNS2;
	};
	forward only;
	auth-nxdomain no;
	listen-on { 10.0.0.254; 10.0.2.254; 10.0.3.254; 127.0.0.1; };
	listen-on-v6 { none; };
};" > /etc/bind/named.conf.options_"$PPP_IFACE"

	# замена конф файла и перезапуск локального dns сервера
	if [[ "$PPP_IFACE" == "$ppp2" || "`ip addr show $ppp2 | grep inet -m 1 | awk '{print $2}'| cut -d '/' -f1`" == "" ]]; then
		cp -f /etc/bind/named.conf.options_"$PPP_IFACE" /etc/bind/named.conf.options
		chown bind:bind /etc/bind/named.conf.options
		/etc/init.d/bind9 restart
	fi
	
	### Перенаправление сайтов на заданые каналы ###
	while read site channel; do
		echo 1;
	done < <(cat /etc/gate/data/channel_dst_sites.txt | grep -v "^#" | grep "[^[:space:]]")

else
	### LOG ###
	echo "`date +%D\ %T` $0: CONNECT PPTP ($PPP_IFACE | $PPP_REMOTE | $PPP_IPPARAM | $PEERNAME)" >> "$log_file"

	### CHECK ###
	mkdir -p /var/run/pptpd-users
	if [ -f /var/run/pptpd-users/$PEERNAME ]; then
    	    kill -HUP `cat /var/run/pptpd-users/$PEERNAME`
    	    rm /var/run/pptpd-users/$PEERNAME
	fi
	cp "/var/run/$PPP_IFACE.pid" "/var/run/pptpd-users/$PEERNAME"

	### ROUTE ###
	ip route add $PPP_REMOTE dev $PPP_IFACE proto kernel scope link  src $PPP_LOCAL table static

	### RATE ###
	/etc/gate/rate/pptp.sh
fi

##########################################
