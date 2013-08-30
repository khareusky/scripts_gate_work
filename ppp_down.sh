#!/bin/bash
#############################################################
#
# export PPP_IFACE PPP_TTY PPP_SPEED PPP_LOCAL PPP_REMOTE PPP_IPPARAM
# - запускается при отключении pppoe либо pptp канала
#
#############################################################
ppp1=ppp101
ppp2=ppp102
ppp3=ppp103

#############################################################
if [[ "$PPP_IFACE" == "$ppp1" || "$PPP_IFACE" == "$ppp2" || "$PPP_IFACE" == "$ppp3" ]]; then
	### LOG ###
	echo "`date +%D\ %T` DISCONNECT PPPoE ($0 | $PPP_IFACE | $PPP_LOCAL)" >> /mnt/sdb1/logs/ppp.log

	### Удаление: чтобы ответ пришедшего запроса извне ушел по тому же интерфейсу ###
	ip rule del from $PPP_LOCAL table $PPP_IFACE prio 10"`echo $PPP_IFACE | cut -d '0' -f2`"

	### NAT ###
	/etc/gate/nat.sh

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