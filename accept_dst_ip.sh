#!/bin/bash
###########################################################
# Цикл по заполнению данными пользовательской цепочки FORWARD_ACCEPT
###########################################################
source /etc/gate/global.sh

 iptables -F FORWARD_ACCEPT
 while read ip temp; do
    iptables -A FORWARD_ACCEPT -d "$ip" -j ACCEPT
 done < <(cat /etc/gate/data/list_accept_dst_ip.txt | grep -v "^#" | grep "[^[:space:]]")

#########################################################################
# вывод на консоль
if [[ -z "$1" ]]; then
    iptables-save -t filter | grep FORWARD_ACCEPT
fi
#########################################################################