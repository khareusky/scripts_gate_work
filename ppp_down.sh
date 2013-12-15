#!/bin/bash
#############################################################
# Данный скрипт запускается при отключении одного из PPPoE каналов для доступа в сеть Интернет.
source global.sh
log "disconnect $PPP_IFACE: $PPP_LOCAL"

# ROUTE
$path/route_ppp_down.sh

# SNAT: Удаление: для подмены исходного ip адреса пакетов на ip адрес сетевого интерфейса для проброса из ЛВС в сеть Интернет
iptables -t nat -D POSTROUTING_SNAT ! -s "$PPP_LOCAL" -o "$PPP_IFACE" -j SNAT --to-source "$PPP_LOCAL"

# Сбросить кеш таблиц маршрутизации отключившегося канала
conntrack -D -q "$PPP_LOCAL"

##########################################
