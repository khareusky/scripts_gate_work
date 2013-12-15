#!/bin/bash
#########################################################################
# просмотр количества подключений каждого хоста
source global.sh

while read $hosts_params; do
    if [[ "$nat" == "1" || "$proxy" == "1" ]]; then
        echo $ip: `conntrack -L 2>/dev/null | grep "ESTABLISHED src=$ip" -c`;
    fi
done < <(cat $hosts_file | grep -v "^#" | grep "[^[:space:]]")

#########################################################################