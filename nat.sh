#!/bin/bash
##########################################################################################
# - доступ из ЛВС в сеть Интернет;
# - доступ из сети Интернет в ЛВС;

##########################################################################################
 int=eth3
 ppp1=ppp101
 ppp2=ppp102
 ppp3=ppp103

# iptables --table nat --flush # очистка всех цепочек в таблице nat

### SNAT #################################################################################
 iptables -t nat -A POSTROUTING -s 10.0.3.0/24 -o "$int" -j SNAT --to-source "`ip addr show $int | grep inet -m 1 | awk '{print $2}'| cut -d '/' -f1`" # доступ wifi в ЛВС

### DNAT ##################################################################################
 iptables -t mangle -F PREROUTING
 iptables -t mangle -F OUTPUT
 iptables -t mangle -A PREROUTING -j CONNMARK --restore-mark
 iptables -t mangle -A OUTPUT -j CONNMARK --restore-mark
 iptables -F FORWARD_DNAT
 while read ip_dst dport1 dport2 temp ; do
    ### NAT PREROUTING ### для подмены ip адреса назначения
    iptables -t nat -A PREROUTING -i "$ppp1" -p tcp -m tcp --dport $dport1 -j DNAT --to-destination "$ip_dst":"$dport2"
    iptables -t nat -A PREROUTING -i "$ppp2" -p tcp -m tcp --dport $dport1 -j DNAT --to-destination "$ip_dst":"$dport2"
    iptables -t nat -A PREROUTING -i "$ppp3" -p tcp -m tcp --dport $dport1 -j DNAT --to-destination "$ip_dst":"$dport2"

    ### MANGLE PREROUTING ### маркировка пакетов по каналам чтобы ответные пакеты уходили в теже каналы
    iptables -t mangle -A PREROUTING -i "$ppp1" -p tcp --dport "$dport1" -m state --state NEW -j CONNMARK --set-mark 0x1
    iptables -t mangle -A PREROUTING -i "$ppp2" -p tcp --dport "$dport1" -m state --state NEW -j CONNMARK --set-mark 0x2
    iptables -t mangle -A PREROUTING -i "$ppp3" -p tcp --dport "$dport1" -m state --state NEW -j CONNMARK --set-mark 0x3

    ### FILTER FORWARD ### предоставление доступа для перехода пакетов между сетевыми интерфейсами
    iptables -A FORWARD_DNAT -o "$int" -d "$ip_dst" -p tcp --dport "$dport2" -j ACCEPT
    iptables -A FORWARD_DNAT -i "$int" -s "$ip_dst" -p tcp --sport "$dport2" -j ACCEPT
 done < <(cat /etc/gate/data/list_of_dnat.txt | grep -v "^#" | grep "[^[:space:]]")

##########################################################################################
