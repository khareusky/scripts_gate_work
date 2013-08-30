#!/bin/bash
#############################################################
# export PPP_IFACE PPP_TTY PPP_SPEED PPP_LOCAL PPP_REMOTE PPP_IPPARAM
# - запускается при подключении pppoe и pptp каналов
#
#############################################################
ppp1=ppp101
ppp2=ppp102
ppp3=ppp103

##########################################
if [[ "$PPP_IFACE" == "$ppp1" || "$PPP_IFACE" == "$ppp2" || "$PPP_IFACE" == "$ppp3" ]]; then # если канал является интернетовским
	### LOG ###
	echo "`date +%D\ %T` CONNECT PPPoE ($0 | $PPP_IFACE | $PPP_LOCAL )" >> /etc/gate/logs/ppp.log

	### Добавление: чтобы ответ пришедшего запроса извне ушел по тому же интерфейсу ###
	ip rule add from $PPP_LOCAL table $PPP_IFACE prio 10"`echo $PPP_IFACE | cut -d '0' -f2`"
	for i in /proc/sys/net/ipv4/conf/*/rp_filter ; do
	    echo 0 > $i
	done
	echo 0 > /proc/sys/net/ipv4/conf/"$PPP_IFACE"/rp_filter

	### CHANNEL DST ###
	/etc/gate/channel/dst.sh auto

	### ROUTE ###
	/etc/gate/route/route_pppoe_up.sh

	### NAT ###
	/etc/gate/nat.sh

	### RATE ###
	/etc/gate/rate/pppoe.sh

	### DNS ###
	if [ "$PPP_IFACE" == "$ppp2" ]; then
		cp -f /etc/bind/named.conf.options_p102 /etc/bind/named.conf.options
		/etc/init.d/bind9 restart
	fi
else
	### LOG ###
	echo "`date +%D\ %T` CONNECT PPTP ($0 | $PPP_IFACE | $PPP_REMOTE | $PPP_IPPARAM | $PEERNAME)" >> /mnt/sdb1/logs/ppp.log

	### CHECK ###
	mkdir -p /var/run/pptpd-users
	if [ -f /var/run/pptpd-users/$PEERNAME ]; then
    	    kill -HUP `cat /var/run/pptpd-users/$PEERNAME`
    	    rm /var/run/pptpd-users/$PEERNAME
	fi
	cp "/var/run/$PPP_IFACE.pid" "/var/run/pptpd-users/$PEERNAME"

	### ROUTE ###
	/etc/gate/route/route_pptp.sh

	### RATE ###
	/etc/gate/rate/pptp.sh
fi
##########################################