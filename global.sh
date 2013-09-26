#!/bin/bash
#########################################################################
int="eth3"
ext1="eth0"
ext2="eth1"
ext3="eth2"
ppp1="ppp101"
ppp2="ppp102"
ppp3="ppp103"
ssh_port="1786"
#path=$(cd $(dirname $0) && pwd)
path="/opt/scripts_gate_work"
script_name="`basename $0`"
log_file="/var/log/gate.log"

int_addr="`ip addr show $int | grep inet -m 1 | awk '{print $2}' | cut -d '/' -f1`";
int_lan="`ip addr show $int | grep inet -m 1 | awk '{print $2}'`";

#########################################################################
squid_first_channel_src="$path/data/squid3_first_channel_src.txt"
squid_second_channel_src="$path/data/squid3_second_channel_src.txt"
squid_third_channel_src="$path/data/squid3_third_channel_src.txt"
squid_first_channel_dst="$path/data/squid3_first_channel_dst.txt"
squid_second_channel_dst="$path/data/squid3_second_channel_dst.txt"
squid_third_channel_dst="$path/data/squid3_third_channel_dst.txt"

#########################################################################
# вывод на консоль
out="$1"
output() {
    if [[ -z "$out" ]]; then
        echo "$script_name: $1";
    fi
}

#########################################################################
# вывод в файл
log() {
    echo "`date +%D\ %T` $script_name: $1" >> "$log_file";
}

#########################################################################
