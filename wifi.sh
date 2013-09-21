#!/bin/bash
#####################################
# скрипт по открытию доступа wifi сети
#####################################
source /etc/gate/global.sh
wifi="$ext3"
wifi_addr="`ip addr show $wifi | grep inet -m 1 | awk '{print $2}' | cut -d '/' -f1`";
wifi_lan="`ip addr show $wifi | grep inet -m 1 | awk '{print $2}'`";

#####################################
# очистка правил
while read prio; do
    ip rule del prio "$prio"
done < <( ip rule show | grep -e '^4[0-9]:' | cut -d ':' -f1)

# заполнение данными
ip rule add from "$wifi_lan" to "$int_lan" table main prio 40 # from wifi to LAN
ip rule add from "$wifi_lan" to "$wifi_lan" table main prio 41 # from wifi to wifi LAN
ip rule add from "$wifi_lan" to all table "$ppp1" prio 42 # from wifi to internet
ip rule add from all to "$wifi_lan" table main prio 43 # from all to wifi

# вывод
output "new rules:
`ip rule ls | grep -e '^4[0-9]:'`"

#####################################
# очистка правил iptables
iptables -F INPUT_WIFI
iptables -F FORWARD_WIFI
iptables -t nat -F POSTROUTING_WIFI
iptables -t mangle -F FORWARD_WIFI

# заполнение данными iptables
iptables -A INPUT_WIFI -i "$wifi" -s "$wifi_lan" -p udp --dport 53 -j ACCEPT # allow dns for wifi
iptables -A INPUT_WIFI -i "$wifi" -s "$wifi_lan" -p udp --dport 67 -j ACCEPT # allow dhcp for wifi
iptables -A INPUT_WIFI -i "$wifi" -s "$wifi_lan" -p icmp -j ACCEPT # allow icmp for wifi
iptables -A FORWARD_WIFI -i "$wifi" -s "$wifi_lan" -j ACCEPT # открытие доступа для wifi в сеть Интернет и ЛВС
iptables -t nat -A POSTROUTING_WIFI -o "$int" -s "$wifi_lan" -d "$int_lan" -j SNAT --to-source "$int_addr" # SNAT wifi в ЛВС
iptables -t mangle -A FORWARD_WIFI -i "$wifi" -s "$wifi_lan" ! -d "$int_lan" -m state --state NEW -j ULOG --ulog-cprange 40 # протоколирование WIFI

# вывод
echo
output "`iptables-save | grep WIFI`"

#####################################
