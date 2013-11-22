#!/bin/bash
#################################################################
# заполнение пользовательской цепочки FORWARD_LOG хостами ЛВС для протоколирования
source global.sh
chain_name="FORWARD_LOG"

#################################################################
# очистка и заполнение
iptables -t mangle -F "$chain_name"
while read $hosts_params; do
    if [[ "$log" == "1" && "$nat" == "1" ]]; then
        iptables -t mangle -A "$chain_name" -s "$ip" -j ULOG --ulog-cprange 40
    fi
done < <(cat $path/data/hosts.txt | grep -v "^#" | grep "[^[:space:]]")

############################################################
# вывод
log "\n`iptables-save -t mangle | grep $chain_name`"

############################################################
