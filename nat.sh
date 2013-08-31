#!/bin/bash
# - доступ из ЛВС в сеть Интернет;
# - доступ из сети Интернет в ЛВС;

##########################################################################################
 int=eth3
 ppp1=ppp101
 ppp2=ppp102
 ppp3=ppp103

# iptables --table nat --flush # очистка всех цепочек в таблице nat

### SNAT #################################################################################
 

### DNAT ##################################################################################
 while read ip_dst dport1 dport2 temp ; do
    ### NAT PREROUTING ### для подмены ip адреса назначения
    iptables -t nat -A PREROUTING -i "$ppp1" -p tcp -m tcp --dport $dport1 -j DNAT --to-destination "$ip_dst":"$dport2"
    iptables -t nat -A PREROUTING -i "$ppp2" -p tcp -m tcp --dport $dport1 -j DNAT --to-destination "$ip_dst":"$dport2"
    iptables -t nat -A PREROUTING -i "$ppp3" -p tcp -m tcp --dport $dport1 -j DNAT --to-destination "$ip_dst":"$dport2"

    ### MANGLE PREROUTING ### маркировка пакетов по каналам чтобы ответные пакеты уходили в теже каналы
    iptables -t mangle -A PREROUTING -i "$ppp1" -p tcp --dport "$dport1" -m state --state NEW -j CONNMARK --set-mark 0x1
    iptables -t mangle -A PREROUTING -i "$ppp2" -p tcp --dport "$dport1" -m state --state NEW -j CONNMARK --set-mark 0x2
    iptables -t mangle -A PREROUTING -i "$ppp3" -p tcp --dport "$dport1" -m state --state NEW -j CONNMARK --set-mark 0x3

 done < <(cat /etc/gate/data/list_of_dnat.txt | grep -v "^#" | grep "[^[:space:]]")

##########################################################################################
