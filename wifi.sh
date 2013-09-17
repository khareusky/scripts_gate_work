#!/bin/bash
 source /etc/gate/global.sh
 wifi_addr="`ip addr show $wifi | grep inet -m 1 | awk '{print $2}' | cut -d '/' -f1`";
 wifi_lan="`ip addr show $wifi | grep inet -m 1 | awk '{print $2}'`";

#####################################
# очистка rule
 while read line; do 
    ip rule del prio "$line"
 done < <( ip rule show | grep -e '^4[0-9]:' | cut -d ':' -f1)

# заполнение данными
 ip rule add from "$wifi_lan" to "$wifi_addr" table main prio 40 # from wifi to gate
 ip rule add from "$wifi_addr" to "$wifi_lan" table main prio 41 # from gate to wifi
 ip rule add from "$wifi_lan" to 10.0.0.0/24 table main prio 42 # wifi to LAN
 ip rule add from 10.0.0.0/24 to "$wifi_lan" table main prio 43 # LAN to wifi
 ip rule add from "$wifi_lan" to all table "$ppp2" prio 44 # wifi to Internet
 ip rule add from all to "$wifi_lan" table main prio 45 # Internet to wifi

 iptables -A INPUT -i "$wifi" -s 10.0.3.0/24 -p udp --dport 53 -j ACCEPT # dns for WIFI
 iptables -A INPUT -i "$wifi" -s 10.0.3.0/24 -p udp --dport 67 -j ACCEPT # dhcp for WIFI
 iptables -A INPUT -i "$wifi" -s 10.0.3.0/24 -p icmp -j ACCEPT # icmp
 iptables -A FORWARD -i "$wifi" -s 10.0.3.0/24 -j ACCEPT # открытие доступа для wifi
 iptables -t nat -A POSTROUTING -o "$int" -s 10.0.3.0/24 -d 10.0.0.0/24 -j SNAT --to-source "`ip addr show $int | grep inet -m 1 | awk '{print $2}'| cut -d '/' -f1`" # SNAT wifi в ЛВС

#####################################
 output "new rules:
`ip rule ls | grep -e '^4[0-9]:'`"
