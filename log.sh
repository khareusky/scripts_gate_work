#!/bin/bash
#################################################################
# Заполнение пользовательской цепочки FORWARD_LOG хостами ЛВС для протоколирования
#################################################################
source global.sh # подключение файла с переменными

iptables -t mangle -F FORWARD_LOG # очистка цепочки
while read $hosts_params; do
	if [[ "$log" == "1" && "$nat" == "1" ]]; then
		iptables -t mangle -A FORWARD_LOG -s "$ip" -j ULOG --ulog-cprange 40
	fi
done < <(cat $path/data/hosts.txt | grep -v "^#" | grep "[^[:space:]]")

############################################################
