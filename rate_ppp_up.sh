#!/bin/bash
################################################################################
source global.sh
iface="$PPP_IFACE"
rate=6000

################################################################################ 
tc qdisc add dev $iface root handle 1:0 htb
tc class add dev $iface parent 1:0 classid 1:1 htb rate "$rate"kbit burst 20k

tc class add dev $iface parent 1:1 classid 1:10 htb rate "$(($rate/2))"kbit ceil "$rate"kbit burst 2k prio 0
tc qdisc add dev $iface parent 1:10 handle 10: sfq perturb 10
tc class add dev $iface parent 1:1 classid 1:11 htb rate "$(($rate/4))"kbit ceil "$rate"kbit burst 2k prio 1
tc qdisc add dev $iface parent 1:11 handle 11: sfq perturb 10
tc class add dev $iface parent 1:1 classid 1:12 htb rate "$(($rate/8))"kbit ceil "$rate"kbit burst 2k prio 2
tc qdisc add dev $iface parent 1:12 handle 12: sfq perturb 10

tc filter add dev $iface protocol ip parent 1:0 prio 1 u32 match ip protocol 1 0xff classid 1:10 # icmp
tc filter add dev $iface protocol ip parent 1:0 prio 1 u32 match ip protocol 0x11 0xff match ip dport 53 0xffff classid 1:10 # dns
tc filter add dev $iface protocol ip parent 1:0 prio 1 u32 match ip protocol 6 0xff match u8 0x02 0xff at nexthdr+13 classid 1:10 # SYN
tc filter add dev $iface protocol ip parent 1:0 prio 1 u32 match ip protocol 6 0xff match u8 0x10 0xff at nexthdr+13 classid 1:10 # ACK

tc filter add dev $iface protocol ip parent 1:0 prio 2 u32 match ip dport 80 0xffff classid 1:11 # http
tc filter add dev $iface protocol ip parent 1:0 prio 2 u32 match ip dport 443 0xffff classid 1:11 # https
tc filter add dev $iface protocol ip parent 1:0 prio 2 u32 match ip dport 21 0xffff classid 1:11 #
tc filter add dev $iface protocol ip parent 1:0 prio 2 u32 match ip dport 20 0xffff classid 1:11 #
tc filter add dev $iface protocol ip parent 1:0 prio 2 u32 match ip dport 22 0xffff classid 1:11 #
tc filter add dev $iface protocol ip parent 1:0 prio 2 u32 match ip dport 1786 0xffff classid 1:11 #
tc filter add dev $iface protocol ip parent 1:0 prio 2 u32 match ip dport 3389 0xffff classid 1:11 #

tc filter add dev $iface protocol ip parent 1:0 prio 3 u32 match ip dst 0/0 flowid 1:12 # other

################################################################################