#!/bin/bash
#########################################################################
# сетевые политики безопасности, которые разрешают прохождение определенным ниже пакетам, а всем другим запрещает
#########################################################################
 source /etc/gate/global.sh # подключение файла с переменными
 iptables --table filter --flush # очистка всех цепочек таблицы FILTER

########################################################################
### FILTER INPUT ###
 iptables -N INPUT_PROXY # создание пользовательских цепочек
 iptables -N INPUT_PPTP

 iptables -P INPUT DROP # состояние по-умолчанию, когда ни одно из правил не сработало
 iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT # пропускать те пакеты, которые уже подключились
 iptables -A INPUT -p tcp --dport "$ssh_port" -j ACCEPT # ssh
 iptables -A INPUT -i lo -j ACCEPT

### INTERNAL INTERFACE ###
 iptables -A INPUT -i "$int" -s 10.0.0.0/24 -p tcp --dport 3128 -j INPUT_PROXY # squid
 iptables -A INPUT -i "$int" -s 10.0.0.0/24 -p udp --dport 53 -j ACCEPT # dns
 iptables -A INPUT -i "$int" -s 10.0.0.0/24 -p tcp --dport 8118 -j ACCEPT # privoxy
 iptables -A INPUT -i "$int" -s 10.0.0.0/24 -p tcp --dport 9050 -j ACCEPT # tor
 iptables -A INPUT -i "$int" -s 10.0.0.0/24 -p tcp --dport 1723 -j INPUT_PPTP # для подключения pptp
 iptables -A INPUT -i "$int" -s 10.0.0.0/24 -p gre -j INPUT_PPTP # для подключения pptp
 iptables -A INPUT -i "$int" -s 10.0.0.0/24 -p icmp -j ACCEPT # icmp

### WIFI INTERFACE ###
 iptables -A INPUT -i "$wifi" -s 10.0.3.0/24 -p udp --dport 53 -j ACCEPT # dns for WIFI
 iptables -A INPUT -i "$wifi" -s 10.0.3.0/24 -p udp --dport 67 -j ACCEPT # dhcp for WIFI
 iptables -A INPUT -i "$wifi" -s 10.0.3.0/24 -p icmp -j ACCEPT # icmp

### pptp ###
 iptables -A INPUT -s 172.25.12.0/24 -p tcp --dport 3128 -j INPUT_PROXY # squid
 iptables -A INPUT -s 172.25.12.0/24 -p udp --dport 53 -j ACCEPT # dns
 iptables -A INPUT -s 172.25.12.0/24 -p icmp -j ACCEPT # icmp

#########################################################################
### FILTER FORWARD ###
 iptables -N FORWARD_DROP # создание пользовательских цепочек
 iptables -N FORWARD_ACCEPT
 iptables -N FORWARD_SNAT
 iptables -N FORWARD_DNAT

 iptables -P FORWARD DROP # состояние по-умолчанию, когда ни одно из правил не сработало
 iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT # пропускать те пакеты, которые уже подключились

 iptables -A FORWARD -j FORWARD_DROP # список запрещенных удаленных ip адресов
 iptables -A FORWARD -j FORWARD_ACCEPT # список удаленных ip адресов, к которым будет разрешен прямой доступ по NAT (SNAT)
 iptables -A FORWARD -j FORWARD_DNAT # список тех внутренних ресурсов ЛВС, к которым будет разрешен доступ извне (DNAT)
 iptables -A FORWARD -i "$int" -j FORWARD_SNAT # список ip адресов ЛВС, кому будет разрешен доступ в сеть Интернет по технологии NAT
 iptables -A FORWARD -i "$wifi" -o "$int" -s 10.0.3.0/24 -d 10.0.0.0/24 -j ACCEPT # доступ для wifi в ЛВС
 iptables -A FORWARD -i "$wifi" -s 10.0.3.0/24 -j ACCEPT # доступ для wifi в сеть Интернет

#########################################################################
### OUTPUT ###
 iptables -P OUTPUT ACCEPT # состояние по-умолчанию, когда ни одно из правил не сработало
 iptables -A OUTPUT -j FORWARD_DROP

#########################################################################
### USER CHAINS ###
 while read name server passwd ip iface proxy nat pptp temp; do
    if [ "$proxy" == "1" ]; then
        iptables -A INPUT_PROXY -s "$ip" -j ACCEPT
    fi
    if [ "$pptp" == "1" ]; then
        iptables -A INPUT_PPTP -s "$ip" -j ACCEPT
    fi
    if [ "$nat" == "1" ]; then ### предоставление доступа перехода пакетов между сетевыми интерфейсами для проброса из ЛВС в сеть Интернет ###
        iptables -A FORWARD_SNAT -s "$ip" -j ACCEPT
    fi
 done < <(cat /etc/gate/data/hosts.txt | grep -v "^#" | grep "[^[:space:]]")

 while read ip; do
    iptables -A FORWARD_DROP -d "$ip" -j REJECT
 done < <(cat /etc/gate/data/list_of_drop.txt | grep -v "^#" | grep "[^[:space:]]")

 while read ip temp; do
    iptables -A FORWARD_ACCEPT -d "$ip" -j ACCEPT
 done < <(cat /etc/gate/data/list_snat_accept.txt | grep -v "^#" | grep "[^[:space:]]")

### предоставление доступа для перехода пакетов между сетевыми интерфейсами для проброса из сети Интернет в ЛВС ###
 while read dport1 ip_dst dport2 temp; do
    iptables -A FORWARD_DNAT -o "$int" -d "$ip_dst" -p tcp --dport "$dport2" -j ACCEPT
    iptables -A FORWARD_DNAT -i "$int" -s "$ip_dst" -p tcp --sport "$dport2" -j ACCEPT
 done < <(cat /etc/gate/data/list_dnat.txt | grep -v "^#" | grep "[^[:space:]]")

#########################################################################
