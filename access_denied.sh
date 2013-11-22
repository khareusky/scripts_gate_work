#!/bin/bash
###########################################################
source global.sh
chain_name="ACCESS_DENIED"

###########################################################
# заполнение
iptables -F "$chain_name"
while read ip temp; do
    iptables -A "$chain_name" -d "$ip" -j REJECT --reject-with icmp-host-prohibited
done < <(cat $path/data/access_denied.txt | grep -v "^#" | grep "[^[:space:]]")

#########################################################################
# вывод
log "\n`iptables-save -t filter | grep $chain_name`"

#########################################################################
