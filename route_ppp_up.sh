#!/bin/bash
########################################################################
source /etc/gate/global.sh

########################################################################
console() {
	if [[ "$enable_out" == "1" ]]; then
		echo "$1";
	fi
}
########################################################################
# проверка на ручной запуск
enable_out="0";
if [[ -z "$PPP_IFACE" ]]; then
	enable_out="1";
	if [[ -z "$1" ]]; then
		console "USAGE: $0 ppp_iface";
		exit 0;
	fi
	PPP_IFACE="$1";
	PPP_LOCAL="`ip addr show $PPP_IFACE | grep inet -m 1 | awk '{print $2}'| cut -d '/' -f1`"
fi

########################################################################
# Если идет обращение непосредственно к шлюзу, то ответные пакеты по тому же каналу
number="`echo -n $PPP_IFACE | tail -c 1`";
while read temp; do # очистка
	ip rule del prio 10"$number";
done < <(ip rule ls | grep ^10"$number")

ip rule add from "$PPP_LOCAL" table "$PPP_IFACE" prio 10"$number";
console "ip rule $ppp1 prio `ip rule | grep ^101`"
console "ip rule $ppp2 prio `ip rule | grep ^102`"
console "ip rule $ppp3 prio `ip rule | grep ^103`"

########################################################################
### TABLES "ppp*" ###
# Перезапись таблицы маршрутизации подключишегося канала
ip route flush table "$PPP_IFACE" # очистка таблицы
ip route add default dev "$PPP_IFACE" table "$PPP_IFACE"
ip route flush cache table "$PPP_IFACE"

# Если какой-то канал отключен, то заполнение пропуска подключившемся каналом 
if [ "`ip route ls table $ppp1`" == "" ]; then
	ip route add default dev "$PPP_IFACE" table "$ppp1"
	ip route flush cache table "$ppp1"
fi
console "ip route ls table $ppp1: `ip route ls table $ppp1`"

if [ "`ip route ls table $ppp2`" == "" ]; then
	ip route add default dev "$PPP_IFACE" table "$ppp2"
	ip route flush cache table "$ppp2"
fi
console "ip route ls table $ppp2: `ip route ls table $ppp2`"

if [ "`ip route ls table $ppp3`" == "" ]; then
	ip route add default dev "$PPP_IFACE" table "$ppp3"
	ip route flush cache table "$ppp3"
fi
console "ip route ls table $ppp3: `ip route ls table $ppp3`"

########################################################################
### TABLE "balance" ###
PPP_LOCAL1="`ip addr show $ppp1 2>/dev/null |grep inet -m 1| awk '{print $2}'| cut -d '/' -f1`"
PPP_REMOTE1="`ip addr show $ppp1 2>/dev/null |grep inet -m 1| awk '{print $4}'| cut -d '/' -f1`"
PPP_LOCAL2="`ip addr show $ppp2 2>/dev/null |grep inet -m 1| awk '{print $2}'| cut -d '/' -f1`"
PPP_REMOTE2="`ip addr show $ppp2 2>/dev/null |grep inet -m 1| awk '{print $4}'| cut -d '/' -f1`"
PPP_LOCAL3="`ip addr show $ppp3 2>/dev/null |grep inet -m 1| awk '{print $2}'| cut -d '/' -f1`"
PPP_REMOTE3="`ip addr show $ppp3 2>/dev/null |grep inet -m 1| awk '{print $4}'| cut -d '/' -f1`"

# Перезапись балансировки между двумя или тремя каналами
ip route flush table balance;
ip route flush cache table balance;
if [[ "$PPP_REMOTE1" != "" && "$PPP_REMOTE2" != "" && "$PPP_REMOTE3" != "" ]]; then
	ip route add default scope global table balance nexthop via $PPP_REMOTE1 dev $ppp1 weight 2 \
							nexthop via $PPP_REMOTE2 dev $ppp2 weight 1 \
							nexthop via $PPP_REMOTE3 dev $ppp3 weight 2;
else if [[ "$PPP_REMOTE1" != "" && "$PPP_REMOTE2" != "" && "$PPP_REMOTE3" == "" ]]; then
	ip route add default scope global table balance nexthop via $PPP_REMOTE1 dev $ppp1 weight 2 \
							nexthop via $PPP_REMOTE2 dev $ppp2 weight 1;
else if [[ "$PPP_REMOTE1" != "" && "$PPP_REMOTE2" == "" && "$PPP_REMOTE3" != "" ]]; then
	ip route add default scope global table balance nexthop via $PPP_REMOTE1 dev $ppp1 weight 1 \
							nexthop via $PPP_REMOTE3 dev $ppp3 weight 1;
else if [[ "$PPP_REMOTE1" == "" && "$PPP_REMOTE2" != "" && "$PPP_REMOTE3" != "" ]]; then
	ip route add default scope global table balance nexthop via $PPP_REMOTE2 dev $ppp2 weight 1 \
							nexthop via $PPP_REMOTE3 dev $ppp3 weight 2;
else
	route add default dev "$PPP_IFACE" table balance; # когда подключился один канал
fi fi fi fi
console "ip route ls table balance: `ip route ls table balance`"

########################################################################
### TABLE "main" ###
if [[ -z "`ip route ls  | grep default`" ]]; then
    ip route add default dev "$PPP_IFACE" table main;
fi

########################################################################
