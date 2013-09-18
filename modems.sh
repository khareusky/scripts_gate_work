#!/bin/bash
#####################################
source /etc/gate/global.sh
ext1_addr="`ip addr show $ext1 | grep inet -m 1 | awk '{print $2}' | cut -d '/' -f1`";
ext2_addr="`ip addr show $ext2 | grep inet -m 1 | awk '{print $2}' | cut -d '/' -f1`";
ext3_addr="`ip addr show $ext3 | grep inet -m 1 | awk '{print $2}' | cut -d '/' -f1`";
ip_modem1="10.0.1.1"
ip_modem2="10.0.2.1"
ip_modem3="10.0.3.1"

#####################################
# очистка правил
while read line; do 
	ip rule del prio "$line"
done < <( ip rule show | grep -e '^1[0-9]:' | cut -d ':' -f1)

while read line; do 
	ip rule del prio "$line"
done < <( ip rule show | grep -e '^5[0-9]:' | cut -d ':' -f1)

#####################################
# заполнение данными
ip rule add from to "$ext1_addr" table main prio 11
ip rule add to "$ext2_addr" table main prio 12
ip rule add to "$ext3_addr" table main prio 13
ip rule add from 10.0.1.1 table main prio 14
ip rule add from 10.0.2.1 table main prio 15
ip rule add from 10.0.3.1 table main prio 16
iptables -A FORWARD -o "$ext1" -d 10.0.1.1 -j ACCEPT
iptables -A FORWARD -o "$ext2" -d 10.0.2.1 -j ACCEPT
iptables -A FORWARD -o "$ext3" -d 10.0.3.1 -j ACCEPT

iptables -t nat -A POSTROUTING -o "$ext1" -d 10.0.1.1 -j SNAT --to-source "`ip addr show $ext1 | grep inet -m 1 | awk '{print $2}'| cut -d '/' -f1`"
iptables -t nat -A POSTROUTING -o "$ext2" -d 10.0.2.1 -j SNAT --to-source "`ip addr show $ext2 | grep inet -m 1 | awk '{print $2}'| cut -d '/' -f1`"
iptables -t nat -A POSTROUTING -o "$ext3" -d 10.0.3.1 -j SNAT --to-source "`ip addr show $ext3 | grep inet -m 1 | awk '{print $2}'| cut -d '/' -f1`"

#####################################
# заполнение данными
ip rule add from "$wifi_lan" to "$wifi_addr" table main prio 40 # from wifi to gate
ip rule add from "$wifi_addr" to "$wifi_lan" table main prio 41 # from gate to wifi
ip rule add from "$wifi_lan" to "$int_lan" table main prio 42 # from wifi to LAN
ip rule add from "$int_lan" to "$wifi_lan" table main prio 43 # from LAN to wifi
ip rule add from "$wifi_lan" to all table "$ppp2" prio 44 # from wifi to internet
ip rule add from all to "$wifi_lan" table main prio 45 # from internet to wifi

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
