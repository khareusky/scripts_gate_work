#!/bin/bash
#########################################################################
# сетевые политики безопасности, которые разрешают прохождение определенным ниже пакетам
#########################################################################
 source /etc/gate/global.sh # подключение файла с переменными
 
#########################################################################
 iptables -F INPUT_PROXY
 iptables -F INPUT_PPTP
 iptables -F FORWARD_SNAT
 while read name server passwd ip iface proxy nat pptp temp; do
    if [ "$proxy" == "1" ]; then
        iptables -A INPUT_PROXY -s "$ip" -j ACCEPT
    fi
    if [ "$pptp" == "1" ]; then
        iptables -A INPUT_PPTP -s "$ip" -j ACCEPT
    fi
    if [ "$nat" == "1" ]; then ### предоставление доступа перехода пакетов между сетевыми интерфейсами для проброса из ЛВС в сеть Интернет ###
        iptables -A FORWARD_SNAT -s "$ip" -j ACCEPT
    fi
 done < <(cat /etc/gate/data/hosts.txt | grep -v "^#" | grep "[^[:space:]]")
 
#########################################################################
 iptables -F FORWARD_DROP
 while read ip; do
    iptables -A FORWARD_DROP -d "$ip" -j REJECT
 done < <(cat /etc/gate/data/list_of_drop.txt | grep -v "^#" | grep "[^[:space:]]")

######################################################################### 
 iptables -F FORWARD_ACCEPT
 while read ip temp; do
    iptables -A FORWARD_ACCEPT -d "$ip" -j ACCEPT
 done < <(cat /etc/gate/data/list_snat_accept.txt | grep -v "^#" | grep "[^[:space:]]")

######################################################################### 
### предоставление доступа для перехода пакетов между сетевыми интерфейсами для проброса из сети Интернет в ЛВС ###
 iptables -F FORWARD_DNAT
 while read dport1 ip_dst dport2 temp; do
    iptables -A FORWARD_DNAT -o "$int" -d "$ip_dst" -p tcp --dport "$dport2" -j ACCEPT
    iptables -A FORWARD_DNAT -i "$int" -s "$ip_dst" -p tcp --sport "$dport2" -j ACCEPT
 done < <(cat /etc/gate/data/list_dnat.txt | grep -v "^#" | grep "[^[:space:]]")

#########################################################################
