#!/bin/bash
#########################################################################
int="eth3"
ext1="eth0"
ext2="eth1"
ext3="eth2"
wifi="eth2"
ppp1="ppp101"
ppp2="ppp102"
ppp3="ppp103"

ssh_port="1786"
#########################################################################
path1="/etc/gate/"
log_file="/var/log/gate.log"

#########################################################################
squid_first_channel_src="/etc/gate/data/squid3_first_channel_src.txt"
squid_second_channel_src="/etc/gate/data/squid3_second_channel_src.txt"
squid_third_channel_src="/etc/gate/data/squid3_third_channel_src.txt"
squid_first_channel_dst="/etc/gate/data/squid3_first_channel_dst.txt"
squid_second_channel_dst="/etc/gate/data/squid3_second_channel_dst.txt"
squid_third_channel_dst="/etc/gate/data/squid3_third_channel_dst.txt"

#########################################################################
# вывод на консоль
out="$1"
output() {
    if [[ -z "$out" ]]; then
		echo "$1";
    fi
}

#########################################################################