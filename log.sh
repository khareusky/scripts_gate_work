#!/bin/bash
####################################################
source global.sh # подключение файла с переменными

####################################################
 iptables -t mangle -F FORWARD
 iptables -t mangle -F OUTPUT
 iptables -t mangle -F INPUT

 iptables -t mangle -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

 iptables -t mangle -N FORWARD_LOG
 iptables -t mangle -F FORWARD_LOG
 iptables -t mangle -A FORWARD -i "$int" -m state --state NEW -j FORWARD_LOG

 while read ip temp
 do
    iptables -t mangle -A FORWARD_LOG -s "$ip" -j ULOG --ulog-cprange 40
 done < <(cat "$hosts" | grep -v "^#" | grep "[^[:space:]]")

#####################################################
