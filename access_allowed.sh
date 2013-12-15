#!/bin/bash
###########################################################
source global.sh
chain_name="ACCESS_ALLOWED"
config="$path/data/access_allowed.txt"
log "begin"

###########################################################
# заполнение
iptables -F "$chain_name"
while read ip temp; do
    iptables -A "$chain_name" -d "$ip" -j ACCEPT
done < <(cat $config | grep -v "^#" | grep "[^[:space:]]")

#########################################################################
log "\n`iptables-save -t filter | grep $chain_name`"
log "end"