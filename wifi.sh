#!/bin/bash
#####################################
# скрипт по открытию доступа wifi сети
source global.sh
wifi="$ext1"
wifi2="$ext3"
wifi_addr="`ip addr show $wifi | grep inet -m 1 | awk '{print $2}' | cut -d '/' -f1`"
wifi_lan="10.0.1.192/26"

#####################################
# очистка правил
while read prio; do
    ip rule del prio "$prio"
done < <( ip rule show | grep -e '^4[0-9]:' | cut -d ':' -f1)

# заполнение данными
ip rule add fwmark 4 table wifi prio 40 # чтобы ответные пакеты уходили по тому же каналу
ip rule add fwmark 5 table wifi2 prio 41 # чтобы ответные пакеты уходили по тому же каналу
ip rule add from "$wifi_lan" to "$int_lan" table main prio 42 # from wifi to LAN
ip rule add from "$wifi_lan" to all table "$ppp1" prio 44 # from wifi to internet
ip rule add from all to "$wifi_lan" table main prio 45 # from all to wifi

ip route flush table wifi
ip route flush table wifi2
ip route add "$wifi_lan" dev "$wifi" table wifi
ip route add "$wifi_lan" dev "$wifi2" table wifi2
ip route flush cache table wifi
ip route flush cache table wifi2

# вывод
log "\n`ip rule ls | grep -e '^4[0-9]:'`"

#####################################
# очистка правил iptables
iptables -F INPUT_WIFI
iptables -F FORWARD_WIFI
iptables -t nat -F POSTROUTING_WIFI
iptables -t mangle -F FORWARD_WIFI
iptables -t mangle -F PREROUTING_WIFI

# заполнение данными iptables
iptables -A INPUT_WIFI -i "$wifi" -s "$wifi_lan" -m state --state NEW -p udp --dport 53 -j ACCEPT # allow dns for wifi
iptables -A INPUT_WIFI -i "$wifi" -p udp --dport 67 -j ACCEPT # allow dhcp for wifi
iptables -A INPUT_WIFI -i "$wifi" -s "$wifi_lan" -m state --state NEW -p icmp -j ACCEPT # allow icmp for wifi

iptables -A INPUT_WIFI -i "$wifi2" -s "$wifi_lan"  -m state --state NEW -p udp --dport 53 -j ACCEPT # allow dns for wifi2
iptables -A INPUT_WIFI -i "$wifi2" -p udp --dport 67 -j ACCEPT # allow dhcp for wifi2
iptables -A INPUT_WIFI -i "$wifi2" -s "$wifi_lan" -m state --state NEW -p icmp -j ACCEPT # allow icmp for wifi2

iptables -A FORWARD_WIFI -i "$wifi" -s "$wifi_lan" -m state --state NEW -j ACCEPT # открытие доступа для wifi в сеть Интернет и ЛВС
iptables -A FORWARD_WIFI -i "$wifi2" -s "$wifi_lan" -m state --state NEW -j ACCEPT # открытие доступа для wifi2 в сеть Интернет и ЛВС

iptables -t nat -A POSTROUTING_WIFI -o "$int" -s "$wifi_lan" -d "$int_lan" -j SNAT --to-source "$int_addr" # SNAT wifi в ЛВС

iptables -t mangle -A FORWARD_WIFI -i "$wifi" -s "$wifi_lan" ! -d "$int_lan" -m state --state NEW -j ULOG --ulog-cprange 40 # протоколирование WIFI
iptables -t mangle -A FORWARD_WIFI -i "$wifi2" -s "$wifi_lan" ! -d "$int_lan" -m state --state NEW -j ULOG --ulog-cprange 40 # протоколирование WIFI2

iptables -t mangle -A PREROUTING_WIFI -i "$wifi" -s "$wifi_lan" -m state --state NEW -j CONNMARK --set-xmark 0x4/0xffffffff
iptables -t mangle -A PREROUTING_WIFI -i "$wifi2" -s "$wifi_lan" -m state --state NEW -j CONNMARK --set-xmark 0x5/0xffffffff

# вывод
log "\n`iptables-save | grep WIFI`"

#####################################
