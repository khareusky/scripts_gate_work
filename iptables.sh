#!/bin/bash
#########################################################################
source global.sh
log "begin"

#####################################
# COMMON
iptables -F INPUT # очистка таблицы
iptables -F FORWARD
iptables -F OUTPUT
iptables -t mangle -F FORWARD
iptables -t mangle -F PREROUTING
iptables -t mangle -F OUTPUT
iptables -t nat -F POSTROUTING

iptables -P INPUT DROP # состояние по-умолчанию, когда ни одно из правил не сработало
iptables -P FORWARD DROP 
iptables -P OUTPUT ACCEPT

#####################################
# BAD PACKETS
iptables -N BAD_PACKETS 2>/dev/null
iptables -A INPUT -j BAD_PACKETS
iptables -A FORWARD -j BAD_PACKETS
iptables -A FORWARD -i "$int" -s "$int_lan" -d 10.0.0.0/8 -m state --state NEW -j DROP
iptables -A FORWARD -i "$int" -s "$int_lan" -d 192.168.0.0/16 -m state --state NEW -j DROP
iptables -A FORWARD -i "$int" -s "$int_lan" -d 172.25.0.0/16 -m state --state NEW -j DROP
iptables -A OUTPUT -j BAD_PACKETS

#####################################
# INPUT COMMON
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT # пропускать те пакеты, которые уже подключились
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -i "$int" -s "$int_lan" -p tcp --dport 22 -m state --state NEW -j ACCEPT # ssh
iptables -A INPUT -i "$int" -s "$int_lan" -p udp --dport 53 -m state --state NEW -j ACCEPT # dns
iptables -A INPUT -i "$int" -s "$int_lan" -p tcp --dport 8118 -m state --state NEW -j ACCEPT # privoxy
iptables -A INPUT -i "$int" -s "$int_lan" -p tcp --dport 9050 -m state --state NEW -j ACCEPT # tor
iptables -A INPUT -i "$int" -s "$int_lan" -p icmp -m state --state NEW -j ACCEPT # icmp

#####################################
# FORWARD COMMON
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT # пропускать те пакеты, которые уже подключились

#####################################
# ACCESS DENIED
iptables -N ACCESS_DENIED 2>/dev/null # список запрещенных ip адресов
iptables -A FORWARD -j ACCESS_DENIED
iptables -A OUTPUT -j ACCESS_DENIED
$path/access_denied.sh # цикл по записи запрещенных хостов в сети Интернет

#####################################
# ACCESS ALLOWED
iptables -N ACCESS_ALLOWED 2>/dev/null # список строк, к которым будет разрешен прямой доступ по NAT (SNAT)
iptables -A FORWARD -i "$int" -s "$int_lan" -m state --state NEW -j ACCESS_ALLOWED
$path/access_allowed.sh

#####################################
# PROXY
iptables -N INPUT_PROXY 2>/dev/null
iptables -A INPUT -i "$int" -s "$int_lan" -p tcp --dport 3128 -m state --state NEW -j INPUT_PROXY # squid
iptables -A INPUT -i "$int" -s "$int_lan" -p tcp --dport 1080 -m state --state NEW -j INPUT_PROXY # socks
$path/proxy.sh # цикл, разрешающий требуемым хостам выход в сеть Интернет через прокси

#####################################
# SNAT
iptables -N FORWARD_SNAT 2>/dev/null
iptables -t nat -N POSTROUTING_SNAT 2>/dev/null

iptables -A FORWARD -i "$int" -s "$int_lan" -m state --state NEW -j FORWARD_SNAT # список ip адресов ЛВС, кому будет разрешен доступ в сеть Интернет по технологии NAT
iptables -t nat -A POSTROUTING -j POSTROUTING_SNAT
$path/snat.sh # заполнение цепочки данными; squid; ip rules

#####################################
# LOGS
iptables -t mangle -N FORWARD_LOG 2>/dev/null # цепочка для протоколирования хостов
iptables -t mangle -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu # принудительная корректировка MSS в пакетах всего транзитного траффика
iptables -t mangle -A FORWARD -i "$int" -s "$int_lan" -m state --state NEW -j FORWARD_LOG # протоколирование компьютеров ЛВС у кого NAT
$path/log.sh # заполнение цепочки FORWARD_LOG хостами

#####################################
# WIFI
ip add show "$ext3" | grep "$ext3":0;
if [ $? == 1 ]; then
    # настройки для работы второй wifi точки
    ifconfig "$ext3" down
    ifconfig "$ext3" hw ether 00:50:bf:59:34:20
    ifconfig "$ext3" up
    ifconfig "$ext3":0 10.0.1.254/24
    /etc/init.d/dhcp3-server restart
fi

iptables -N INPUT_WIFI 2>/dev/null
iptables -N FORWARD_WIFI 2>/dev/null
iptables -t nat -N POSTROUTING_WIFI 2>/dev/null
iptables -t mangle -N FORWARD_WIFI 2>/dev/null
iptables -t mangle -N PREROUTING_WIFI 2>/dev/null

iptables -A INPUT -j INPUT_WIFI
iptables -A FORWARD -j FORWARD_WIFI
iptables -t nat -A POSTROUTING -j POSTROUTING_WIFI
iptables -t mangle -A FORWARD -j FORWARD_WIFI
iptables -t mangle -A PREROUTING -j PREROUTING_WIFI

$path/wifi.sh

#####################################
# modems
iptables -N FORWARD_MODEM 2>/dev/null
iptables -t nat -N POSTROUTING_MODEM 2>/dev/null

iptables -A FORWARD -m state --state NEW -j FORWARD_MODEM
iptables -t nat -A POSTROUTING -j POSTROUTING_MODEM

$path/modems.sh # модемы

#####################################
iptables -t mangle -A PREROUTING -j CONNMARK --restore-mark # перезапуск маркировки пакетов, чтобы ответные пакеты на пакеты запросов (из сети Инетернет в ЛВС) перенаправлялись на теже Интернет-каналы
iptables -t mangle -A OUTPUT -j CONNMARK --restore-mark

#####################################
log "end"
