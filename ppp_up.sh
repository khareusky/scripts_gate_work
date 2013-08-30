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

	### CHANNEL DST ###
	/etc/gate/channel/dst.sh auto

	### ROUTE ###
	/etc/gate/route/route_pppoe_up.sh

	### NAT POSTROUTING ### для подмены исходного ip адреса на ip адрес сетевого интерфейса
	iptables -t nat -A POSTROUTING ! -s "$PPP_LOCAL" -o "$PPP_IFACE" -j SNAT --to-source "$PPP_LOCAL"

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