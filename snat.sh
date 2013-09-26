#!/bin/bash
###########################################################
# Цикл по записи хостов в цепочку FORWARD_SNAT
###########################################################
source global.sh

###########################################################
### FILTER FORWARD_SNAT ###
 iptables -F FORWARD_SNAT
 while read name server passwd ip iface proxy nat temp; do
    if [[ "$nat" == "1" ]]; then ### предоставление доступа перехода пакетов между сетевыми интерфейсами для проброса из ЛВС в сеть Интернет ###
        iptables -A FORWARD_SNAT -s "$ip" -j ACCEPT
    fi
 done < <(cat $path/data/hosts.txt | grep -v "^#" | grep "[^[:space:]]")

###########################################################
