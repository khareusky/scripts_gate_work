#!/bin/bash
#########################################################################
source global.sh

#####################################
# INPUT COMMON
iptables -F INPUT
iptables -P INPUT DROP # состояние по-умолчанию, когда ни одно из правил не сработало
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT # пропускать те пакеты, которые уже подключились
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -i "$int" -s "$int_lan" -p tcp --dport 22 -m state --state NEW -j ACCEPT # ssh
iptables -A INPUT -i "$int" -s "$int_lan" -p udp --dport 53 -m state --state NEW -j ACCEPT # dns
iptables -A INPUT -i "$int" -s "$int_lan" -p tcp --dport 8118 -m state --state NEW -j ACCEPT # privoxy
iptables -A INPUT -i "$int" -s "$int_lan" -p tcp --dport 9050 -m state --state NEW -j ACCEPT # tor
iptables -A INPUT -i "$int" -s "$int_lan" -p icmp -m state --state NEW -j ACCEPT # icmp

#####################################
# FORWARD COMMON
iptables -F FORWARD
iptables -P FORWARD DROP # состояние по-умолчанию, когда ни одно из правил не сработало
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT # пропускать те пакеты, которые уже подключились

#####################################
# OUTPUT
iptables -P OUTPUT ACCEPT # состояние по-умолчанию, когда ни одно из правил не сработало

#####################################
# BAD PACKETS
iptables -N BAD_PACKETS 2>/dev/null
iptables -A FORWARD -j BAD_PACKETS
iptables -A OUTPUT -j BAD_PACKETS

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
iptables -A FORWARD -i "$int" -s "$int_lan" -m state --state NEW -j FORWARD_SNAT # список ip адресов ЛВС, кому будет разрешен доступ в сеть Интернет по технологии NAT
$path/snat.sh # заполнение цепочки данными; squid; ip rules

#####################################
# DNAT
iptables -N FORWARD_DNAT 2>/dev/null # список тех внутренних ресурсов ЛВС, к которым будет разрешен доступ извне (DNAT)
iptables -t nat -N PREROUTING_DNAT 2>/dev/null # пользовательская цепочка для днатирования пакетов из сети Интернет в ЛВС
iptables -t mangle -N PREROUTING_DNAT 2>/dev/null # пользовательская цепочка для днатированых пакетов, чтобы пакеты уходили в теже каналы

iptables -A FORWARD -m state --state NEW -j FORWARD_DNAT
iptables -t nat -A PREROUTING -j PREROUTING_DNAT
iptables -t mangle -A PREROUTING -j PREROUTING_DNAT

$path/dnat.sh # заполнение цепочек данными

#####################################
# LOGS
iptables -t mangle -N FORWARD_LOG 2>/dev/null # цепочка для протоколирования хостов
iptables -t mangle -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu # принудительная корректировка MSS в пакетах всего транзитного траффика
iptables -t mangle -A FORWARD -i "$int" -s "$int_lan" -m state --state NEW -j FORWARD_LOG # протоколирование компьютеров ЛВС у кого NAT
$path/log.sh # заполнение цепочки FORWARD_LOG хостами

#####################################
# WIFI
ifconfig "$ext3" down
ifconfig "$ext3" hw ether 00:50:bf:59:34:20
ifconfig "$ext3" up
ifconfig "$ext3":0 10.0.1.254/24
/etc/init.d/dhcp3-server restart

iptables -N INPUT_WIFI 2>/dev/null
iptables -N FORWARD_WIFI 2>/dev/null
iptables -t nat -N POSTROUTING_WIFI 2>/dev/null
iptables -t mangle -N FORWARD_WIFI 2>/dev/null
iptables -t mangle -N PREROUTING_WIFI 2>/dev/null

iptables -A INPUT -j INPUT_WIFI
iptables -A FORWARD -m state --state NEW -j FORWARD_WIFI
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

