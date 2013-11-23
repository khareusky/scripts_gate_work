#!/bin/bash
#####################################
source global.sh
ext1_addr="`ip addr show $ext1 | grep inet -m 1 | awk '{print $2}' | cut -d '/' -f1`";
ext2_addr="`ip addr show $ext2 | grep inet -m 1 | awk '{print $2}' | cut -d '/' -f1`";
ext3_addr="`ip addr show $ext3 | grep inet -m 1 | awk '{print $2}' | cut -d '/' -f1`";
ip_modem1="10.0.1.1"
ip_modem2="10.0.2.1"
ip_modem3="10.0.3.1"

#####################################
# очистка правил
while read prio; do
    ip rule del prio "$prio"
done < <( ip rule show | grep -e '^1[0-9]:' | cut -d ':' -f1)

# заполнение данными
ip rule add from all to "$ip_modem1" table main prio 11
ip rule add from all to "$ip_modem2" table main prio 12
ip rule add from all to "$ip_modem3" table main prio 13
ip rule add from "$ip_modem1" to all table main prio 14
ip rule add from "$ip_modem2" to all table main prio 15
ip rule add from "$ip_modem3" to all table main prio 16

# вывод
log "\n`ip rule ls | grep -e '^1[0-9]:'`"

#####################################
### SNAT ###
# очистка правил iptables
iptables -F FORWARD_MODEM
iptables -t nat -F POSTROUTING_MODEM

# заполнение данными iptables
iptables -A FORWARD_MODEM -o "$ext1" -d "$ip_modem1" -m state --state NEW -j ACCEPT
iptables -A FORWARD_MODEM -o "$ext2" -d "$ip_modem2" -m state --state NEW -j ACCEPT
iptables -A FORWARD_MODEM -o "$ext3" -d "$ip_modem3" -m state --state NEW -j ACCEPT
iptables -t nat -A POSTROUTING_MODEM -o "$ext1" ! -s "$ext1_addr" -d "$ip_modem1" -j SNAT --to-source "$ext1_addr"
iptables -t nat -A POSTROUTING_MODEM -o "$ext2" ! -s "$ext2_addr" -d "$ip_modem2" -j SNAT --to-source "$ext2_addr"
iptables -t nat -A POSTROUTING_MODEM -o "$ext3" ! -s "$ext3_addr" -d "$ip_modem3" -j SNAT --to-source "$ext3_addr"

# вывод
log "\n`iptables-save | grep MODEM`"

#####################################
### SQUID ###
# настройки по модемам внесены непосредственно в сами конф файлы squid (tcp_outgoing_address.conf)

#####################################
