#!/bin/bash
###########################################################
# предоставление доступа перехода пакетов между сетевыми интерфейсами для проброса из ЛВС в сеть Интернет
source global.sh
chain_name="FORWARD_SNAT"
log "begin"

###########################################################
# очистка и заполнение
iptables -F "$chain_name"
while read $hosts_params; do
    if [[ "$nat" == "1" ]]; then 
        iptables -A "$chain_name" -s "$ip" -j ACCEPT
    fi
done < <(cat $hosts_file | grep -v "^#" | grep "[^[:space:]]")

###########################################################
log "\n`iptables-save -t filter | grep $chain_name`"
log "end"
