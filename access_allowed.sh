#!/bin/bash
###########################################################
source global.sh
chain_name="ACCESS_ALLOWED"

###########################################################
# заполнение
iptables -F "$chain_name"
while read ip temp; do
    iptables -A "$chain_name" -d "$ip" -j ACCEPT
done < <(cat $path/data/access_allowed.txt | grep -v "^#" | grep "[^[:space:]]")

#########################################################################
# вывод
log "\n`iptables-save -t filter | grep $chain_name`"

#########################################################################