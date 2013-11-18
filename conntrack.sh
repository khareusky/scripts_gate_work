#!/bin/bash
#########################################################################
source global.sh

while read $hosts_params; do
    if [[ "$nat" == "1" || "$proxy" == "1" ]]; then
        echo $ip: `conntrack -L 2>/dev/null | grep "ESTABLISHED src=$ip" -c`;
    fi
done < <(cat $path/data/hosts.txt | grep -v "^#" | grep "[^[:space:]]")

#########################################################################