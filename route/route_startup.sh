#!/bin/bash
########################################################################
 int=eth3
 ext1=eth0
 ext2=eth1
 ext3=eth2

########################################################################
 count=`ip rule | grep -c "lookup static"`
 for ((i=1;i<=count;i++)); do
     ip rule del table static
 done
 ip rule add table static prio 1

 ip route add 10.0.0.0/24 dev $int src 10.0.0.1 table static
 ip route add 10.0.1.0/24 dev $ext1 src 10.0.1.254 table static
 ip route add 10.0.2.0/24 dev $ext2 src 10.0.2.254 table static
 ip route add 10.0.3.0/24 dev $ext3 src 10.0.3.254 table static
 ip route add 10.1.0.0/24 dev $int src 10.1.0.254 table static
 ip route add 10.2.0.0/24 dev $int src 10.2.0.254 table static
 ip route add 10.3.0.0/24 dev $int src 10.3.0.254 table static

#########################################################################
 ip route ls table static