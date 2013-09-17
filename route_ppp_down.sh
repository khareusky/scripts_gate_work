#!/bin/bash
########################################################################
source /etc/gate/global.sh
PPP_LOCAL1="`ip addr show $ppp1|grep inet -m 1| awk '{print $2}'| cut -d '/' -f1`"
PPP_REMOTE1="`ip addr show $ppp1|grep inet -m 1| awk '{print $4}'| cut -d '/' -f1`"
PPP_LOCAL2="`ip addr show $ppp2|grep inet -m 1| awk '{print $2}'| cut -d '/' -f1`"
PPP_REMOTE2="`ip addr show $ppp2|grep inet -m 1| awk '{print $4}'| cut -d '/' -f1`"
PPP_LOCAL3="`ip addr show $ppp3|grep inet -m 1| awk '{print $2}'| cut -d '/' -f1`"
PPP_REMOTE3="`ip addr show $ppp3|grep inet -m 1| awk '{print $4}'| cut -d '/' -f1`"

########################################################################
# Если идет обращение непосредственно к шлюзу, то ответные пакеты по тому же каналу
number="`echo -n $PPP_IFACE | tail -c 1`";
while read temp; do # очистка
	ip rule del prio 10"$number";
done < <(ip rule ls | grep ^10"$number")

########################################################################
### TABLES "ppp*" ###
# Поиск хотябы одного подключившегося канала
if [[ "$PPP_REMOTE1" != "" ]]; then
	PPP_IFACE_CONNECTED="$ppp1"
else if [[ "$PPP_REMOTE2" != "" ]]; then
	PPP_IFACE_CONNECTED="$ppp2"
else if [[ "$PPP_REMOTE3" != "" ]]; then
	PPP_IFACE_CONNECTED="$ppp3"
fi fi fi
 
# Если какой-то канал отключен, то заполнение пропуска подключившемся каналом 
ip route del default dev "$PPP_IFACE" table "$ppp1"
ip route del default dev "$PPP_IFACE" table "$ppp2"
ip route del default dev "$PPP_IFACE" table "$ppp3"

if [ "`ip route ls table $ppp1`" == "" ]; then
	ip route add default dev "$PPP_IFACE_CONNECTED" table "$ppp1"
	ip route flush cache table "$ppp1"
fi
if [ "`ip route ls table $ppp2`" == "" ]; then
	ip route add default dev "$PPP_IFACE_CONNECTED" table "$ppp2"
	ip route flush cache table "$ppp2"
fi
if [ "`ip route ls table $ppp3`" == "" ]; then
	ip route add default dev "$PPP_IFACE_CONNECTED" table "$ppp3"
	ip route flush cache table "$ppp3"
fi

########################################################################
### TABLE "balance" ###
# Перезапись балансировки между двумя каналами
ip route flush table balance;
ip route flush cache table balance;
if [[ "$PPP_REMOTE1" != "" && "$PPP_REMOTE2" != "" && "$PPP_REMOTE3" == "" ]]; then
	ip route add default scope global nexthop via $PPP_REMOTE1 dev $ppp1 weight 2 \
									  nexthop via $PPP_REMOTE2 dev $ppp2 weight 1 table balance;
else if [[ "$PPP_REMOTE1" != "" && "$PPP_REMOTE2" == "" && "$PPP_REMOTE3" != "" ]]; then
	ip route add default scope global nexthop via $PPP_REMOTE1 dev $ppp1 weight 1 \
								      nexthop via $PPP_REMOTE3 dev $ppp3 weight 1 table balance;
else if [[ "$PPP_REMOTE1" == "" && "$PPP_REMOTE2" != "" && "$PPP_REMOTE3" != "" ]]; then
	ip route add default scope global nexthop via $PPP_REMOTE2 dev $ppp2 weight 1 \
								      nexthop via $PPP_REMOTE3 dev $ppp3 weight 2 table balance;
else
	route add default dev "$PPP_IFACE_CONNECTED" table balance; # когда остался один канал
fi fi fi

########################################################################
