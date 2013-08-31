#!/bin/bash
###########################################################
#
# - перенаправление на определенный канал сети Интернета по исходящему адресу компьютера в ЛВС
#
###########################################################
 ppp1=ppp101
 ppp2=ppp102
 ppp3=ppp103
 prio=500

###########################################################
### RULES SRC CLEAR ###
 while read line
 do
    ip rule del prio $line
 done < <( ip rule show | grep -e '^5[0-9][0-9]:' | cut -d ':' -f1)

###########################################################
### SQUID LOCAL ###
 rm -f /etc/squid3/first_channel_src.txt
 rm -f /etc/squid3/second_channel_src.txt
 rm -f /etc/squid3/third_channel_src.txt

 touch /etc/squid3/first_channel_src.txt
 touch /etc/squid3/second_channel_src.txt
 touch /etc/squid3/third_channel_src.txt
 while read name server passwd ip iface proxy nat pptp channel rate1 rate2 log comment
 do
 	if [[ "$channel" == "0" && "$channel" == "*" && "$proxy" == "0" ]]; then
 	    continue
 	fi

 	if [ "$channel" == "$ppp1" ]; then
 		echo $ip >> /etc/squid3/first_channel_src.txt
 		continue
 	fi
 	if [ "$channel" == "$ppp2" ]; then
 		echo $ip >> /etc/squid3/second_channel_src.txt
 		continue
 	fi
 	if [ "$channel" == "$ppp3" ]; then
 		echo $ip >> /etc/squid3/third_channel_src.txt
 		continue
 	fi
 done < <(cat /etc/gate/data/chap-secrets | grep -v "^#" | grep "[^[:space:]]")

 a=$(cat /var/run/squid3.pid 2>/dev/null)
 if [ "$a" == "" ]; then
 	/etc/init.d/squid3 start
 else
 	/etc/init.d/squid3 reload
 fi

###########################################################
### RULES SQUID LOCAL ###
 ip rule add from 10.1.0.254 table $ppp1 prio "$(($prio+4))"
 ip rule add from 10.2.0.254 table $ppp2 prio "$(($prio+5))"
 ip rule add from 10.3.0.254 table $ppp3 prio "$(($prio+6))"

###########################################################
### RULES SRC CLEAR ###
 while read line
 do
    ip rule del prio $line
 done < <( ip rule show | grep -e '^2[0-9][0-9][0-9][0-9]:' | cut -d ':' -f1)

###########################################################
### RULES SRC NAT ###
 prio=20000
 ip rule add fwmark 0x1/0x1 table "$ppp1" prio "$(($prio+1))"
 ip rule add fwmark 0x2/0x2 table "$ppp2" prio "$(($prio+2))"
 ip rule add fwmark 0x3/0x3 table "$ppp3" prio "$(($prio+3))"
 prio="$(($prio+4))"
 while read name server passwd ip iface proxy nat pptp channel rate1 rate2 log comment
 do
    if [[ "$channel" == "0" || "$channel" == "*" ]]; then
        continue
    fi

    if [ "$channel" == "$ppp1" ]; then
        ip rule add from "$ip" table $ppp1 prio $prio
    fi

    if [ "$channel" == "$ppp2" ]; then
        ip rule add from "$ip" table $ppp2 prio $prio
    fi

    if [ "$channel" == "$ppp3" ]; then
        ip rule add from "$ip" table $ppp3 prio $prio
    fi
    let "prio = prio + 1"
 done < <(cat /etc/gate/data/chap-secrets | grep -v "^#" | grep "[^[:space:]]")
 let "prio = prio + 1"
 
###########################################################
