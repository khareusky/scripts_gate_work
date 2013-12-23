#!/bin/bash
#################################################################
# - ограничение пропускной способности компьютеров ЛВС как входного траффика так и выходного
# - приоритезация исходящего и входящего траффика на внутреннем интерфейсе шлюза
source global.sh
rate_down_default=1500
rate_up_default=100
uid=10
log "begin"

################################################################
### INT ###
tc qdisc del dev $int root
tc qdisc del dev ifb0 root

# exit 0;
tc qdisc add dev $int root handle 1:0 htb default 5
tc class add dev $int parent 1:0 classid 1:2 htb rate 100mbit burst 30k
tc class add dev $int parent 1:2 classid 1:1 htb rate 20mbit burst 20k
tc class add dev $int parent 1:2 classid 1:5 htb rate 85mbit burst 20k prio 4

tc qdisc add dev ifb0 root handle 1:0 htb default 5
tc class add dev ifb0 parent 1:0 classid 1:2 htb rate 100mbit burst 30k
tc class add dev ifb0 parent 1:2 classid 1:1 htb rate 20mbit burst 20k
tc class add dev ifb0 parent 1:2 classid 1:5 htb rate 85mbit burst 20k prio 4

tc qdisc del dev $int ingress
tc qdisc add dev $int ingress
tc filter add dev $int parent ffff: protocol ip u32 match u32 0 0 action mirred egress redirect dev ifb0

while read $hosts_params; do
    rate1="$rate_down";
    rate2="$rate_up";
    if [ "$rate_down" == "*" ]; then
        rate1=$rate_down_default
    fi
    if [ "$rate_up" == "*" ]; then
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
    tc filter add dev $int protocol ip parent 1:0 prio 2 u32 match ip dst $ip match ip sport 1080 0xffff classid 1:"$(($uid+2))" # socks
    tc filter add dev $int protocol ip parent 1:0 prio 2 u32 match ip dst $ip match ip sport 8118 0xffff classid 1:"$(($uid+2))" # privoxy
    tc filter add dev $int protocol ip parent 1:0 prio 2 u32 match ip dst $ip match ip sport 9050 0xffff classid 1:"$(($uid+2))" # tor

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
    
    log "$ip: $rate1/$rate2"
done < <(cat $hosts_file | grep -v "^#" | grep "[^[:space:]]")
################################################################
log "end"

