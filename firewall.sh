#!/bin/bash
#########################################################################
#
# - сетевая политика безопасности доступа к серверу со стороны ЛВС
# - сетевая политика безопасности доступа к серверу со стороны сети Интернет
# - сетевая политика безопасности транзитного траффика с ЛВС в сеть Интернет
# - сетевая политика безопасности транзитного траффика с PPTP в сеть Интернет
# - сетевая политика безопасности транзитного траффика с WIFI в сеть Интернет
# - сетевая политика безопасности транзитного траффика с сети Интернет в ЛВС,PPTP
# - сетевая политика безопасности по ограничению доступа к определенным ресурсам сети Интернет
# - сетевая политика безопасности по разрешению доступа к определенным ресурсам сети Интернет
#
#########################################################################
 int=eth3
 ext1=eth0
 ext2=eth1
 ext3=eth2
 wifi=eth2
 iptables --table filter --flush
 iptables -N INPUT_PROXY
 iptables -N INPUT_PPTP
 iptables -N FORWARD_SNAT
 iptables -N FORWARD_DROP
 iptables -N FORWARD_ACCEPT
 iptables -N FORWARD_DNAT

########################################################################
### INPUT ###
 ssh_port=1786
 iptables -F INPUT
 iptables -P INPUT ACCEPT
 iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
 iptables -A INPUT -p tcp --dport "$ssh_port" -j ACCEPT
 iptables -A INPUT -i lo -j ACCEPT

### eth3 ###
 iptables -A INPUT -i $int -s 10.0.0.0/24 -p tcp --dport 3128 -j INPUT_PROXY # squid
 iptables -A INPUT -i $int -s 10.0.0.0/24 -p udp --dport 53 -j ACCEPT # dns
 iptables -A INPUT -i $int -s 10.0.0.0/24 -p tcp --dport 8118 -j ACCEPT # privoxy
 iptables -A INPUT -i $int -s 10.0.0.0/24 -p tcp --dport 9050 -j ACCEPT # tor
 iptables -A INPUT -i $int -s 10.0.0.0/24 -p tcp --dport 80 -j ACCEPT # torrent
 iptables -A INPUT -i $int -s 10.0.0.0/24 -p tcp --dport 1723 -j INPUT_PPTP # для подключения pptp
 iptables -A INPUT -i $int -s 10.0.0.0/24 -p gre -j INPUT_PPTP # для подключения pptp
 iptables -A INPUT -i $int -s 10.0.0.0/24 -p icmp -j ACCEPT # icmp

### wifi ###
 iptables -A INPUT -i $wifi -p udp --dport 53 -j ACCEPT
 iptables -A INPUT -i $wifi -p udp --dport 67 -j ACCEPT

### pptp ###
 iptables -A INPUT -s 172.25.12.0/24 -p tcp --dport 3128 -j INPUT_PROXY # squid
 iptables -A INPUT -s 172.25.12.0/24 -p udp --dport 53 -j ACCEPT # dns
 iptables -A INPUT -s 172.25.12.0/24 -p icmp -j ACCEPT # icmp

 iptables -P INPUT DROP

#########################################################################
### FORWARD ###
 iptables -P FORWARD ACCEPT
 iptables -F FORWARD # очистить данный список
 iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
 iptables -A FORWARD -j FORWARD_DROP # список запрещенных ip
 iptables -A FORWARD -s 10.0.0.0/24 -i $int -j FORWARD_ACCEPT # список ip адресов удаленных ресурсов, к которым разрешен прямой доступ по NAT
 iptables -A FORWARD -j FORWARD_DNAT # список тех внутренних ресурсов, к которым нужен доступ извне (DNAT)
# iptables -A FORWARD -s 10.0.0.0/24 -i $int -j FORWARD_SNAT # список ip, кому надо будет NAT
 iptables -A FORWARD -i $int -j FORWARD_SNAT # список ip, кому надо будет NAT
 iptables -A FORWARD -s 10.0.3.0/24 -i $wifi -j ACCEPT # прямой доступ для wifi в Интернет через NAT и ЛВС
 iptables -P FORWARD DROP

#########################################################################
### OUTPUT ###
 iptables -P OUTPUT ACCEPT
 iptables -F OUTPUT
 iptables -A OUTPUT -j FORWARD_DROP

#########################################################################
### CHAINS ###
 iptables -F INPUT_PROXY
 iptables -F INPUT_PPTP
 while read name server passwd ip iface proxy nat pptp channel rate1 rate2 log comment
 do
    if [ "$proxy" == "1" ]; then
        iptables -A INPUT_PROXY -s $ip -j ACCEPT
    fi
    if [ "$pptp" == "1" ]; then
        iptables -A INPUT_PPTP -s $ip -j ACCEPT
    fi
 done < <(cat /etc/gate/data/chap-secrets | grep -v "^#" | grep "[^[:space:]]")

#########################
 iptables -F FORWARD_DROP
 while read ip
 do
    iptables -A FORWARD_DROP -d "$ip" -j REJECT
 done < <(cat /etc/gate/data/list_of_drop.txt | grep -v "^#" | grep "[^[:space:]]")

#########################
 iptables -F FORWARD_ACCEPT
 while read ip temp
 do
    iptables -A FORWARD_ACCEPT -d "$ip" -j ACCEPT
 done < <(cat /etc/gate/data/dst_ip_nat_accept.txt | grep -v "^#" | grep "[^[:space:]]")

### предоставление доступа для перехода пакетов между сетевыми интерфейсами
 iptables -F FORWARD_SNAT
 while read name server passwd ip iface proxy nat temp ; do
    if [ "$nat" == "1" ]; then
        iptables -A FORWARD_SNAT -s $ip -j ACCEPT
    fi
 done < <(cat /etc/gate/data/chap-secrets | grep -v "^#" | grep "[^[:space:]]")

#########################################################################
 iptables-save
