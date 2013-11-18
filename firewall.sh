#!/bin/bash
#########################################################################
# сетевые политики безопасности, которые разрешают прохождение определенным ниже пакетам
#########################################################################
source global.sh # подключение файла с переменными

#########################################################################
iptables -F INPUT_PROXY
while read $hosts_params; do
    if [ "$proxy" == "1" ]; then
        iptables -A INPUT_PROXY -s "$ip" -j ACCEPT
    fi
done < <(cat $path/data/hosts.txt | grep -v "^#" | grep "[^[:space:]]")

#########################################################################
iptables -F FORWARD_DROP
while read ip; do
    iptables -A FORWARD_DROP -d "$ip" -j REJECT
done < <(cat $path/data/list_of_drop.txt | grep -v "^#" | grep "[^[:space:]]")

######################################################################### 
