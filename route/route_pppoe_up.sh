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
### TABLE "static" ###
 ip route add $PPP_REMOTE dev $PPP_IFACE src $PPP_LOCAL table static
 ip route flush cache table static

########################################################################
### TABLES "ppp10*" ###
# Перезапись таблицы маршрутизации подключишегося канала
 ip route del default table $PPP_IFACE
 ip route add default dev $PPP_IFACE table $PPP_IFACE
 ip route flush cache table $PPP_IFACE

# Если какой-то канал отключен, то заполнение пропуска подключившемся каналом 
 if [ "`ip route ls table $ppp1`" == "" ]; then
        ip route add default dev $PPP_IFACE table "$ppp1"
        ip route flush cache table "$ppp1"
 fi
 if [ "`ip route ls table $ppp2`" == "" ]; then
        ip route add default dev $PPP_IFACE table "$ppp2"
        ip route flush cache table "$ppp2"
 fi
 if [ "`ip route ls table $ppp3`" == "" ]; then
        ip route add default dev $PPP_IFACE table "$ppp3"
        ip route flush cache table "$ppp3"
 fi

########################################################################
### TABLE "main" ###
# Перезапись баллансировки между двумя или тремя каналами 
 ip route del default
 if [[ "$PPP_REMOTE1" != "" && "$PPP_REMOTE2" != "" && "$PPP_REMOTE3" != "" ]]; then
     ip route add default scope global nexthop via $PPP_REMOTE1 dev $ppp1 weight 2 \
                                       nexthop via $PPP_REMOTE2 dev $ppp2 weight 1 \
                                       nexthop via $PPP_REMOTE3 dev $ppp3 weight 2
 else if [[ "$PPP_REMOTE1" != "" && "$PPP_REMOTE2" != "" && "$PPP_REMOTE3" == "" ]]; then
     ip route add default scope global nexthop via $PPP_REMOTE1 dev $ppp1 weight 2 \
                                       nexthop via $PPP_REMOTE2 dev $ppp2 weight 1
 else if [[ "$PPP_REMOTE1" != "" && "$PPP_REMOTE2" == "" && "$PPP_REMOTE3" != "" ]]; then
     ip route add default scope global nexthop via $PPP_REMOTE1 dev $ppp1 weight 1 \
                                       nexthop via $PPP_REMOTE3 dev $ppp3 weight 1
 else if [[ "$PPP_REMOTE1" == "" && "$PPP_REMOTE2" != "" && "$PPP_REMOTE3" != "" ]]; then
     ip route add default scope global nexthop via $PPP_REMOTE2 dev $ppp2 weight 1 \
                                       nexthop via $PPP_REMOTE3 dev $ppp3 weight 2
 else 
	route add default dev "$PPP_IFACE" # когда подключился один канал
 fi fi fi fi
 ip route flush cache table main

########################################################################
