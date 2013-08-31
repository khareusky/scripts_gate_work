#!/bin/bash
#######################################################################
#
# Если класс промежуточный (не leaf и не root), в него _не_ нужно вводить qdisk и фильтры(rules) соответственно. Приоритеты в таких классах так-же не работают, они нужны только для leafs
#
#######################################################################
 iface="$PPP_IFACE"
 ip="$PPP_REMOTE"
 rate_down_default=6000

#######################################################################
 while read name server passwd ip_home iface_home proxy nat pptp channel rate1 rate2 log comment
 do
    if [ "$ip" == "$ip_home" ]; then
        if [ "$rate1" == "*" ]; then
            rate1=$rate_down_default
        fi
        rate=$rate1

	tc qdisc add dev $iface root handle 1:0 htb
	tc class add dev $iface parent 1:0 classid 1:1 htb rate "$rate"kbit burst 20k

	tc class add dev $iface parent 1:1 classid 1:10 htb rate "$(($rate/2))"kbit ceil "$rate"kbit burst 2k prio 0
	tc qdisc add dev $iface parent 1:10 handle 10: sfq perturb 10
	tc class add dev $iface parent 1:1 classid 1:11 htb rate "$(($rate/4))"kbit ceil "$rate"kbit burst 2k prio 1
	tc qdisc add dev $iface parent 1:11 handle 11: sfq perturb 10
	tc class add dev $iface parent 1:1 classid 1:12 htb rate "$(($rate/8))"kbit ceil "$rate"kbit burst 2k prio 2
	tc qdisc add dev $iface parent 1:12 handle 12: sfq perturb 10

	tc filter add dev $iface protocol ip parent 1:0 prio 1 u32 match ip dst $ip match ip protocol 1 0xff classid 1:10 # icmp
	tc filter add dev $iface protocol ip parent 1:0 prio 1 u32 match ip dst $ip match ip protocol 0x11 0xff match ip sport 53 0xffff classid 1:10 # dns
	tc filter add dev $iface protocol ip parent 1:0 prio 1 u32 match ip dst $ip match ip sport 3389 0xffff classid 1:10 # rdp
	tc filter add dev $iface protocol ip parent 1:0 prio 1 u32 match ip dst $ip match ip sport 22 0xffff classid 1:10 # ssh
	tc filter add dev $iface protocol ip parent 1:0 prio 1 u32 match ip dst $ip match ip sport 1786 0xffff classid 1:10 # ssh
	tc filter add dev $iface protocol ip parent 1:0 prio 1 u32 match ip dst $ip match ip protocol 6 0xff match u8 0x02 0xff at nexthdr+13 classid 1:10 # SYN
	tc filter add dev $iface protocol ip parent 1:0 prio 1 u32 match ip dst $ip match ip protocol 6 0xff match u8 0x10 0xff at nexthdr+13 classid 1:10 # ACK
	
	tc filter add dev $iface protocol ip parent 1:0 prio 2 u32 match ip dst $ip match ip sport 3128 0xffff classid 1:11 # squid
	tc filter add dev $iface protocol ip parent 1:0 prio 2 u32 match ip dst $ip match ip sport 80 0xffff classid 1:11 # http
	tc filter add dev $iface protocol ip parent 1:0 prio 2 u32 match ip dst $ip match ip sport 443 0xffff classid 1:11 # https
	tc filter add dev $iface protocol ip parent 1:0 prio 2 u32 match ip dst $ip match ip sport 25 0xffff classid 1:11 # smtp
	tc filter add dev $iface protocol ip parent 1:0 prio 2 u32 match ip dst $ip match ip sport 110 0xffff classid 1:11 # pop3
	
	tc filter add dev $iface protocol ip parent 1:0 prio 3 u32 match ip dst $ip match ip src 0/0 classid 1:12 # other
	break;
    fi
 done < <(cat /etc/gate/data/hosts.txt | grep -v "^#" | grep "[^[:space:]]")
#########################################################################