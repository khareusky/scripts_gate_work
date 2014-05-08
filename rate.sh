#!/bin/bash
##########################################
source global.sh

################################################################
### common ###
tc qdisc del dev $int root
tc qdisc del dev ifb0 root

tc qdisc add dev $int root handle 1:0 htb default 5
tc class add dev $int parent 1:0 classid 1:1 htb rate 100mbit burst 30k

tc qdisc add dev ifb0 root handle 1:0 htb default 5
tc class add dev ifb0 parent 1:0 classid 1:1 htb rate 100mbit burst 30k

tc qdisc del dev $int ingress
tc qdisc add dev $int ingress
tc filter add dev $int parent ffff: protocol ip u32 match u32 0 0 action mirred egress redirect dev ifb0

################################################################
uid=10
while read ip ifc rate1 rate2 temp; do
    # DOWN #
    tc class add dev $int parent 1:1 classid 1:$uid htb rate "$rate1"kbit burst 2k prio 1
    tc filter add dev $int protocol ip parent 1:0 prio 1 u32 match ip dst $ip flowid 1:$uid
    tc qdisc add dev $int parent 1:"$uid" handle "$uid": sfq perturb 10

    # UP #
    tc class add dev ifb0 parent 1:1 classid 1:$uid htb rate "$rate2"kbit burst 2k prio 1
    tc filter add dev ifb0 protocol ip parent 1:0 prio 1 u32 match ip src $ip flowid 1:$uid
    tc qdisc add dev ifb0 parent 1:"$uid" handle "$uid": sfq perturb 10

    let "uid = uid + 1"
done < <(cat "$hosts" | grep -v "^#" | grep "[^[:space:]]")
#tc class ls dev $int

################################################################

