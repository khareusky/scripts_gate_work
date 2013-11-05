#!/bin/bash
##########################################
source global.sh
uid=10

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
### 46 ###
while read ip rate1 rate2 temp; do
    # DOWN #
    tc class add dev $int parent 1:1 classid 1:$uid htb rate "$rate1"kbit burst 2k prio 1
    tc filter add dev $int protocol ip parent 1:0 prio 1 u32 match ip dst $ip flowid 1:$uid
    tc qdisc add dev $int parent 1:"$uid" handle "$uid": sfq perturb 10

    # UP #
    tc class add dev ifb0 parent 1:1 classid 1:$uid htb rate "$rate2"kbit burst 2k prio 1
    tc filter add dev ifb0 protocol ip parent 1:0 prio 1 u32 match ip src $ip flowid 1:$uid
    tc qdisc add dev ifb0 parent 1:"$uid" handle "$uid": sfq perturb 10

    let "uid = uid + 1"
done < <(cat "$ext46_file" | grep -v "^#" | grep "[^[:space:]]")
tc class ls dev $int

exit 0;
################################################################
 while read name server passwd ip iface proxy nat pptp channel rate1 rate2 log comment
 do
        if [ "$iface" != "int" ]; then
            continue
        fi
        if [ "$rate1" == "*" ]; then
            rate1=$rate_down_default
        fi
        if [ "$rate2" == "*" ]; then
            rate2=$rate_up_default
        fi

    ### DOWN ###
        rate="$(($rate1+16))"
        tc class add dev $int parent 1:1 classid 1:$uid htb rate "$(($rate/4))"kbit ceil "$rate"kbit burst 4k

        tc class add dev $int parent 1:"$uid" classid 1:"$(($uid+1))" htb rate "$(($rate/2))"kbit ceil "$rate"kbit burst 2k prio 0
        tc qdisc add dev $int parent 1:"$(($uid+1))" handle "$(($uid+1))": sfq perturb 10
        tc class add dev $int parent 1:"$uid" classid 1:"$(($uid+2))" htb rate "$(($rate/4))"kbit ceil "$rate"kbit burst 2k prio 1
        tc qdisc add dev $int parent 1:"$(($uid+2))" handle "$(($uid+2))": sfq perturb 10
        tc class add dev $int parent 1:"$uid" classid 1:"$(($uid+3))" htb rate "$(($rate/8))"kbit ceil "$rate"kbit burst 2k prio 2
        tc qdisc add dev $int parent 1:"$(($uid+3))" handle "$(($uid+3))": sfq perturb 10

        tc filter add dev $int protocol ip parent 1:0 prio 1 u32 match ip dst $ip match ip protocol 1 0xff classid 1:"$(($uid+1))" # icmp
        tc filter add dev $int protocol ip parent 1:0 prio 1 u32 match ip dst $ip match ip protocol 11 0xff classid 1:"$(($uid+1))" # udp
        tc filter add dev $int protocol ip parent 1:0 prio 1 u32 match ip dst $ip match ip protocol 0x11 0xff match ip sport 53 0xffff classid 1:"$(($uid+1))" # dns
        tc filter add dev $int protocol ip parent 1:0 prio 1 u32 match ip dst $ip match ip protocol 6 0xff match u8 0x02 0xff at nexthdr+13 classid 1:"$(($uid+1))" # SYN
        tc filter add dev $int protocol ip parent 1:0 prio 1 u32 match ip dst $ip match ip protocol 6 0xff match u8 0x10 0xff at nexthdr+13 classid 1:"$(($uid+1))" # ACK

        tc filter add dev $int protocol ip parent 1:0 prio 2 u32 match ip dst $ip match ip sport 3128 0xffff classid 1:"$(($uid+2))" # squid
        tc filter add dev $int protocol ip parent 1:0 prio 2 u32 match ip dst $ip match ip sport 8118 0xffff classid 1:"$(($uid+2))" # privoxy
        tc filter add dev $int protocol ip parent 1:0 prio 2 u32 match ip dst $ip match ip sport 9050 0xffff classid 1:"$(($uid+2))" # tor

        tc filter add dev $int protocol ip parent 1:0 prio 3 u32 match ip dst $ip match ip protocol 0x2f 0xff classid 1:"$(($uid+3))" # pptp
        tc filter add dev $int protocol ip parent 1:0 prio 3 u32 match ip dst $ip classid 1:"$(($uid+3))" # all

    ### UP ###
        rate="$(($rate2+16))"
        tc class add dev ifb0 parent 1:1 classid 1:$uid htb rate "$(($rate/4))"kbit ceil "$rate"kbit burst 4k

        tc class add dev ifb0 parent 1:"$uid" classid 1:"$(($uid+1))" htb rate "$(($rate/2))"kbit ceil "$rate"kbit burst 2k prio 0
        tc qdisc add dev ifb0 parent 1:"$(($uid+1))" handle "$(($uid+1))": sfq perturb 10
        tc class add dev ifb0 parent 1:"$uid" classid 1:"$(($uid+2))" htb rate "$(($rate/4))"kbit ceil "$rate"kbit burst 2k prio 1
        tc qdisc add dev ifb0 parent 1:"$(($uid+2))" handle "$(($uid+2))": sfq perturb 10
        tc class add dev ifb0 parent 1:"$uid" classid 1:"$(($uid+3))" htb rate "$(($rate/8))"kbit ceil "$rate"kbit burst 2k prio 2
        tc qdisc add dev ifb0 parent 1:"$(($uid+3))" handle "$(($uid+3))": sfq perturb 10

        tc filter add dev ifb0 protocol ip parent 1:0 prio 1 u32 match ip src $ip match ip protocol 1 0xff classid 1:"$(($uid+1))" # icmp
        tc filter add dev ifb0 protocol ip parent 1:0 prio 1 u32 match ip src $ip match ip protocol 0x11 0xff match ip dport 53 0xffff classid 1:"$(($uid+1))" # dns
        tc filter add dev ifb0 protocol ip parent 1:0 prio 1 u32 match ip src $ip match ip protocol 0x06 0xff match u8 0x02 0x02 at nexthdr+13 classid 1:"$(($uid+1))" # SYN
        tc filter add dev ifb0 protocol ip parent 1:0 prio 1 u32 match ip src $ip match ip protocol 6 0xff match u8 0x10 0x10 at nexthdr+13 classid 1:"$(($uid+1))" # ACK

        tc filter add dev ifb0 protocol ip parent 1:0 prio 2 u32 match ip src $ip match ip dport 3128 0xffff classid 1:"$(($uid+2))" # squid
        tc filter add dev ifb0 protocol ip parent 1:0 prio 2 u32 match ip src $ip match ip dport 8118 0xffff classid 1:"$(($uid+2))" # privoxy
        tc filter add dev ifb0 protocol ip parent 1:0 prio 2 u32 match ip src $ip match ip dport 9050 0xffff classid 1:"$(($uid+2))" # tor

        tc filter add dev ifb0 protocol ip parent 1:0 prio 3 u32 match ip src $ip match ip protocol 0x2f 0xff classid 1:"$(($uid+3))" # pptp
        tc filter add dev ifb0 protocol ip parent 1:0 prio 3 u32 match ip src $ip classid 1:"$(($uid+3))" # all
        let "uid = uid + 4"
 done < <(cat $path/data/hosts.txt | grep -v "^#" | grep "[^[:space:]]")

################################################################

