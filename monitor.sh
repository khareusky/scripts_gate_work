#!/bin/bash
##########################################
source global.sh

if [[ -z "$1" ]]; then
    echo sttt | iftop -n -N -i eth0 -m 6M -f "(src host $int_addr and src port 3128 or src port 1080 or src port 53) or 
					      (dst net 10.0.0.0/24 and not src net 10.0.0.0/8 and not arp and not net 224.0.0.0/4 and not net 239.0.0.0/8 and not host 255.255.255.255) and 
					      not host $proxy_ip"
else
    tail -c 20000 -f "$log_file"
fi

##########################################
