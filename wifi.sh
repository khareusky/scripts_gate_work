#!/bin/bash
#####################################
source /etc/gate/global.sh
wifi="$ext3"
wifi_addr="`ip addr show $wifi | grep inet -m 1 | awk '{print $2}' | cut -d '/' -f1`";
wifi_lan="`ip addr show $wifi | grep inet -m 1 | awk '{print $2}'`";

#####################################
# очистка правил
while read line; do 
	ip rule del prio "$line"
done < <( ip rule show | grep -e '^4[0-9]:' | cut -d ':' -f1)

#####################################
# заполнение данными
ip rule add from "$wifi_lan" table main prio 40 # from wifi to LAN
ip rule add from "$wifi_lan" table "$ppp2" prio 41 # from wifi to internet
ip rule add to "$wifi_lan" table main prio 42 # from all to wifi

iptables -A INPUT -i "$wifi" -s "$wifi_lan" -p udp --dport 53 -j ACCEPT # allow dns for wifi
iptables -A INPUT -i "$wifi" -s "$wifi_lan" -p udp --dport 67 -j ACCEPT # allow dhcp for wifi
iptables -A INPUT -i "$wifi" -s "$wifi_lan" -p icmp -j ACCEPT # allow icmp for wifi
iptables -A FORWARD -i "$wifi" -s "$wifi_lan" -j ACCEPT # открытие доступа для wifi в сеть Интернет и ЛВС
iptables -t nat -A POSTROUTING -o "$int" -s "$wifi_lan" -d "$int_lan" -j SNAT --to-source "$int_addr" # SNAT wifi в ЛВС

#####################################
# вывод
output "new rules:
`ip rule ls | grep -e '^4[0-9]:'`"

#####################################
