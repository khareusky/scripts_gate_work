#!/bin/bash
###########################################################
source global.sh
chain_name="ACCESS_DENIED"
config="$path/data/access_denied.txt"
log "begin"

###########################################################
# заполнение
iptables -F "$chain_name"
while read ip temp; do
    iptables -A "$chain_name" -d "$ip" -j REJECT --reject-with icmp-host-prohibited
done < <(cat $config | grep -v "^#" | grep "[^[:space:]]")

#########################################################################
log "\n`iptables-save -t filter | grep $chain_name`"
log "end"

