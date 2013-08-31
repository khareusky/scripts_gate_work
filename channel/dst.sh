#!/bin/bash
###########################################################
# Принудительное перенаправление на определенный канал Интернета исходя из адреса удаленного ресурса.
# Запускается либо вручную либо при первом подключении какого-либо канала

###########################################################
 ppp1=ppp101
 ppp2=ppp102
 ppp3=ppp103
 prio=10000

###########################################################
### Проверка на ручной запуск либо уже запущенность ###
if [[ "$1" == "auto" && `ip rule ls | grep "^10000:"` != "" ]]; then
    exit 0;
fi

###########################################################
### Удалние вставленных нами правил (при ручном перезапуске скрипта) ###
 while read line
 do
    ip rule del prio $line
 done < <( ip rule show | grep -e '^1[0-9][0-9][0-9][0-9]:' | cut -d ':' -f1)

###########################################################
### NAT DST ###
 filename="/etc/gate/data/list_of_dst.txt"
 while read ip channel access name
 do
 	if [[ "$channel" == "0" || "$channel" == "*" ]]; then
 	    continue
 	fi

 	if [ "$channel" == "1" ]; then
 		if [ "$name" == "1" ]; then
 		    while read line
 		    do
				ip rule add to "$line" table $ppp1  prio $prio
				let "prio = prio + 1"
 		    done < <(host "$ip" | grep has | awk '{print $4}')
 		else
 		    ip rule add to "$ip" table $ppp1 prio $prio
 		fi
 	fi
 	if [ "$channel" == "2" ]; then
 		if [ "$name" == "1" ]; then
 		    while read line
 		    do
 			ip rule add to "$line" table $ppp2 prio $prio
 			let "prio = prio + 1"
 		    done < <(host "$ip" | grep has | awk '{print $4}')
 		else
 		    ip rule add to "$ip" table $ppp2 prio $prio
 		fi
 	fi
 	if [ "$channel" == "3" ]; then
 		if [ "$name" == "1" ]; then
 		    while read line
 		    do
 			ip rule add to "$line" table $ppp3 prio $prio
 			let "prio = prio + 1"
 		    done < <(host "$ip" | grep has | awk '{print $4}')
 		else
 		    ip rule add to "$ip" table $ppp3 prio $prio
 		fi
 	fi
 	let "prio = prio + 1"
 done < <(cat "$filename" | grep -v "^#" | grep "[^[:space:]]")

###########################################################
### SQUID DST ###
 rm -f /etc/squid3/first_channel_dst.txt
 rm -f /etc/squid3/second_channel_dst.txt
 rm -f /etc/squid3/third_channel_dst.txt

 touch /etc/squid3/first_channel_dst.txt
 touch /etc/squid3/second_channel_dst.txt
 touch /etc/squid3/third_channel_dst.txt

 while read ip channel access name
 do
 	if [ "$channel" == "0" ]; then
 	    continue
 	fi

 	if [ "$channel" == "1" ]; then
 		if [ "$name" == "1" ]; then
 		    host "$ip" | grep has | awk '{print $4}' >> /etc/squid3/first_channel_dst.txt
 		else
 		    echo $ip >> /etc/squid3/first_channel_dst.txt
 		fi
 		continue
 	fi
 	if [ "$channel" == "2" ]; then
 		if [ "$name" == "1" ]; then
 		    host "$ip" | grep has | awk '{print $4}' >> /etc/squid3/second_channel_dst.txt
 		else
 		    echo $ip >> /etc/squid3/second_channel_dst.txt
 		fi
 		continue
 	fi
 	if [ "$channel" == "3" ]; then
 		if [ "$name" == "1" ]; then
 		    host "$ip" | grep has | awk '{print $4}' >> /etc/squid3/third_channel_dst.txt
 		else
 		    echo $ip >> /etc/squid3/third_channel_dst.txt
 		fi
 		continue
 	fi
 done < <(cat /etc/gate/data/list_of_dst.txt | grep -v "^#" | grep "[^[:space:]]")

 a=$(cat /var/run/squid3.pid 2>/dev/null)
 if [ "$a" == "" ]; then
 	/etc/init.d/squid3 start
 else
 	/etc/init.d/squid3 reload
 fi

###########################################################
