#!/bin/bash
##########################################
source global.sh

##########################################
# VOKZAL
iface=$vokzal
table="vokzal"

# rules
while read line; do
    ip rule del prio "$line"
done < <( ip rule show | grep -e '^1[0-9][0-9][0-9]:' | cut -d ':' -f1)

ip rule add from 80.237.70.158 table "$table" prio 1000
ip rule add to 80.237.70.158 table "$table" prio 1001
prio=1002
while read ip ifc temp
do
    if [ "$ifc" == "$table" ]; then
        ip rule add from "$ip" to all table "$table" prio "$prio"
        ip rule add from all to "$ip" table "$table" prio $(($prio+1))
        let "prio = prio + 2"
    fi
done < <(cat "$hosts" | grep -v "^#" | grep "[^[:space:]]")
#log "`ip rule`"

# route
ip route flush table "$table"
ip route add default via 80.237.70.157 dev $iface table "$table"
ip route add 10.30.0.0/16 dev $int proto kernel  scope link  src 10.30.254.249 table "$table"
ip route flush cache table "$table"
#log "`ip route ls table $table`"

# iptables
iptables --flush FORWARD_VOKZAL
while read ip ifc temp
do
    if [ "$ifc" == "$table" ]; then
        iptables -A FORWARD_VOKZAL -s "$ip" -j ACCEPT
        iptables -A FORWARD_VOKZAL -d "$ip" -j ACCEPT
    fi
done < <(cat "$hosts" | grep -v "^#" | grep "[^[:space:]]")
#log "`iptables-save  | grep FORWARD_INTERZ`"

##########################################
# MY_BOX
iface=$mybox
table="mybox"

# rules
while read line; do
    ip rule del prio "$line"
done < <( ip rule show | grep -e '^2[0-9][0-9][0-9]:' | cut -d ':' -f1)

ip rule add from 62.32.67.38 table "$table" prio 2000
ip rule add to 62.32.67.38 table "$table" prio 2001
prio=2002
while read ip ifc temp
do
    if [ "$ifc" == "$table" ]; then
        ip rule add from "$ip" to all table "$table" prio "$prio"
        ip rule add from all to "$ip" table "$table" prio $(($prio+1))
        let "prio = prio + 2"
    fi
done < <(cat "$hosts" | grep -v "^#" | grep "[^[:space:]]")
#log "`ip rule`"

# route
ip route flush table "$table"
ip route add default via 62.32.67.37 dev $iface table "$table"
ip route add 10.30.0.0/16 dev $int proto kernel  scope link  src 10.30.254.249 table "$table"
ip route add 46.34.130.10/32 dev $int via 10.30.11.19 table "$table"
ip route add 46.34.130.11/32 dev $int via 10.30.11.19 table "$table"
ip route add 46.34.130.0/24 dev $int proto kernel  scope link  src 46.34.130.253 table "$table"
ip route flush cache table "$table"
#log "`ip route ls table "$table"`"

# iptables
iptables --flush FORWARD_MYBOX
while read ip ifc temp
do
    if [ "$ifc" == "$table" ]; then
        iptables -A FORWARD_MYBOX -s "$ip" -j ACCEPT
        iptables -A FORWARD_MYBOX -d "$ip" -j ACCEPT
    fi
done < <(cat "$hosts" | grep -v "^#" | grep "[^[:space:]]")
#log "`iptables-save  | grep FORWARD_MYBOX`"

##########################################
# INTER_Z
iface=$interz
table="interz"

# rules
while read line; do
    ip rule del prio "$line"
done < <( ip rule show | grep -e '^3[0-9][0-9][0-9]:' | cut -d ':' -f1)

ip rule add from 10.64.251.160 table "$table" prio 3000
ip rule add to 10.64.251.160 table "$table" prio 3001
prio=3002
while read ip ifc temp
do
    if [ "$ifc" == "$table" ]; then
        ip rule add from "$ip" to all table "$table" prio "$prio"
        ip rule add from all to "$ip" table "$table" prio $(($prio+1))
        let "prio = prio + 2"
    fi
done < <(cat "$hosts" | grep -v "^#" | grep "[^[:space:]]")
#log "`ip rule`"

# route
ip route flush table "$table"
ip route add default via 10.64.248.1 dev $iface table "$table"
ip route add 10.30.0.0/16 dev $int proto kernel  scope link  src 10.30.254.249 table "$table"
ip route flush cache table "$table"
#log "`ip route ls table "$table"`"

# iptables
iptables --flush FORWARD_INTERZ
while read ip ifc temp
do
    if [ "$ifc" == "$table" ]; then
        iptables -A FORWARD_INTERZ -s "$ip" -j ACCEPT
        iptables -A FORWARD_INTERZ -d "$ip" -j ACCEPT
    fi
done < <(cat "$hosts" | grep -v "^#" | grep "[^[:space:]]")
#log "`iptables-save  | grep FORWARD_INTERZ`"

##########################################
