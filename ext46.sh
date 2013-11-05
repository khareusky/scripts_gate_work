#!/bin/bash
##########################################
source global.sh
prio=100
log "set up 46.34.130.0/24"

##########################################
# rules
while read line; do
    ip rule del prio "$line"
done < <( ip rule show | grep -e '^1[0-9][0-9]:' | cut -d ':' -f1)
while read ip temp
do
    ip rule add from "$ip" to all table ext46 prio "$prio"
    ip rule add from all to "$ip" table ext46 prio $(($prio+1))
    let "prio = prio + 2"
done < <(cat "$ext46_file" | grep -v "^#" | grep "[^[:space:]]")
log "`ip rule`"

##########################################
# route
ip route flush table ext46
ip route add 46.34.130.10 via 10.30.11.19 metric 100 table ext46 # ВЧ
ip route add 46.34.130.11 via 10.30.11.19 metric 100 table ext46 # ВЧ
ip route add default via 10.30.254.254 table ext46
ip route flush cache table ext46
log "`ip route ls table ext46`"

##########################################
# iptables
iptables --flush FORWARD_46
while read ip temp
do
    iptables -A FORWARD_46 -s "$ip" -j ACCEPT
    iptables -A FORWARD_46 -d "$ip" -j ACCEPT
done < <(cat "$ext46_file" | grep -v "^#" | grep "[^[:space:]]")
log "`iptables-save  | grep FORWARD_46`"

##########################################
