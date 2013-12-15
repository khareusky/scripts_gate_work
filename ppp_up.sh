#!/bin/bash
#############################################################
# Данный скрипт запускается при подключении одного из PPPoE каналов для доступа в сеть Интернет.
source global.sh
log "connect $PPP_IFACE: local ip = $PPP_LOCAL; remote ip = $PPP_REMOTE; dns1 = $DNS1; dns2 = $DNS2;"

# ROUTE
$path/route_ppp_up.sh

# SNAT: Добавление: для подмены исходного ip адреса пакетов на ip адрес сетевого интерфейса при пробросе из ЛВС в сеть Интернет ###
iptables -t nat -A POSTROUTING_SNAT ! -s "$PPP_LOCAL" -o "$PPP_IFACE" -j SNAT --to-source "$PPP_LOCAL"

# RATE
$path/rate_ppp_up.sh

# ACCESS DENIED
$path/access_denied.sh

# ACCESS ALLOWED
$path/access_allowed.sh

##########################################
