#!/bin/bash
#########################################################################
# сетевые политики безопасности, которые разрешают прохождение пакетам
source global.sh
chain_name="INPUT_PROXY"
log "begin"

#########################################################################
# очистка и заполнение
iptables -F "$chain_name"
while read $hosts_params; do
    if [ "$proxy" == "1" ]; then
        iptables -A "$chain_name" -s "$ip" -j ACCEPT
    fi
done < <(cat $hosts_file | grep -v "^#" | grep "[^[:space:]]")

# вывод
log "\n`iptables-save -t filter | grep $chain_name`"

#########################################################################
# очистка правил
while read prio; do
    ip rule del prio "$prio"
done < <( ip rule show | grep -e '^6[0-9]:' | cut -d ':' -f1)

# заполнение
ip rule add from 10.1.0.254 table "$ppp1" prio 61
ip rule add from 10.2.0.254 table "$ppp2" prio 62
ip rule add from 10.3.0.254 table "$ppp3" prio 63
ip rule add to 10.1.0.254 table main prio 64
ip rule add to 10.2.0.254 table main prio 65
ip rule add to 10.3.0.254 table main prio 66

######################################################################### 
log "\n`ip rule ls | grep -e '^6[0-9]:'`"
log "end"