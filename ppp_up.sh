#!/bin/bash
#############################################################
# Данный скрипт запускается при подключении одного из PPPoE каналов для доступа в сеть Интернет.
#############################################################
source /etc/gate/global.sh

if [[ "$PPP_IFACE" == "$ppp1" || "$PPP_IFACE" == "$ppp2" || "$PPP_IFACE" == "$ppp3" ]]; then # если канал является интернетовским
	### LOG ###
	echo "`date +%D\ %T` $0: CONNECT PPPoE ($PPP_IFACE | $PPP_LOCAL )" >> "$log_file"

	### CHANNEL DST ###
	/etc/gate/channel/dst.sh auto

	### ROUTE ###
	/etc/gate/route/route_pppoe_up.sh

	### SNAT: Добавление: для подмены исходного ip адреса пакетов на ip адрес сетевого интерфейса при пробросе из ЛВС в сеть Интернет ###
	iptables -t nat -A POSTROUTING ! -s "$PPP_LOCAL" -o "$PPP_IFACE" -j SNAT --to-source "$PPP_LOCAL"

	### DNAT
	while read dport1 ip_dst dport2 temp ; do
		### DNAT: Добавление: для подмены ip адреса назначения пакетов на ip адрес требуемого компьютера при пробросе из сети Интернет в ЛВС ###
		iptables -t nat -A PREROUTING -i "$PPP_IFACE" -p tcp -m tcp --dport "$dport1" -j DNAT --to-destination "$ip_dst":"$dport2"
		
		### DNAT: Добавление: маркировка пакетов по каналам, чтобы ответные пакеты на запросы в ЛВС уходили в теже каналы ###
		iptables -t mangle -A PREROUTING -i "$PPP_IFACE" -p tcp --dport "$dport1" -m state --state NEW -j CONNMARK --set-mark 0x`echo -n "$PPP_IFACE" | tail -c 1`
	done < <(cat /etc/gate/data/list_dnat.txt | grep -v "^#" | grep "[^[:space:]]")
	
	### RATE ###
	/etc/gate/rate/pppoe.sh

	### DNS ###
	if [ "$PPP_IFACE" == "$ppp2" ]; then
		cp -f /etc/bind/named.conf.options_p102 /etc/bind/named.conf.options
		/etc/init.d/bind9 restart
	fi
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
	/etc/gate/route/route_pptp.sh

	### RATE ###
	/etc/gate/rate/pptp.sh
fi

##########################################
# проверка на первое подключение к сети Интернет
 PPP_REMOTE1="`ip addr show $ppp1|grep inet -m 1| awk '{print $4}'| cut -d '/' -f1`"
 PPP_REMOTE2="`ip addr show $ppp2|grep inet -m 1| awk '{print $4}'| cut -d '/' -f1`"
 PPP_REMOTE3="`ip addr show $ppp3|grep inet -m 1| awk '{print $4}'| cut -d '/' -f1`"
 if [[ "$PPP_REMOTE1" != "" && "$PPP_REMOTE2" == "" && "$PPP_REMOTE3" == "" ]]; then
    /etc/gate/internet_up.sh
 fi
 if [[ "$PPP_REMOTE1" == "" && "$PPP_REMOTE2" != "" && "$PPP_REMOTE3" == "" ]]; then
    /etc/gate/internet_up.sh
 fi
 if [[ "$PPP_REMOTE1" == "" && "$PPP_REMOTE2" == "" && "$PPP_REMOTE3" != "" ]]; then
    /etc/gate/internet_up.sh
 fi

##########################################