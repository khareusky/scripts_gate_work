#!/bin/bash
##########################################################
# - запускает необходимые модули
# - настраивает сетевые параметры
log "begin"

##########################################################
# ifb0
/sbin/modprobe ifb
ip link set dev ifb0 up

##########################################################

# Изменение параметров SYSCTL

# Выключение rp_filter для всех интерфейсов:
# опция, фильтрующая пакеты, которые не могут уйти через тот же интерфейс что и пришли
for i in /proc/sys/net/ipv4/conf/*/rp_filter ; do
	echo 0 > $i
done
echo 0 > /proc/sys/net/ipv4/conf/ppp101/rp_filter
echo 0 > /proc/sys/net/ipv4/conf/ppp102/rp_filter
echo 0 > /proc/sys/net/ipv4/conf/ppp103/rp_filter

# Включение форвардинга
echo 1 > /proc/sys/net/ipv4/ip_forward

# Включение форвардинга для VPN
echo 1 > /proc/sys/net/ipv4/ip_dynaddr
echo 0 > /proc/sys/net/ipv4/conf/all/rp_filter
echo 0 > /proc/sys/net/ipv4/conf/default/rp_filter

exit 0;

# Увеличение размера очередей
echo 32000000 > /proc/sys/net/ipv4/netfilter/ip_conntrack_max
# Время ожидания до закрытия соединения
echo 14400 > /proc/sys/net/ipv4/netfilter/ip_conntrack_tcp_timeout_established
# Время ожидания до посылки FIN пакета
echo 60 > /proc/sys/net/ipv4/netfilter/ip_conntrack_tcp_timeout_fin_wait
# Время ожидания до посылки FIN пакета
echo 10 > /proc/sys/net/ipv4/netfilter/ip_conntrack_tcp_timeout_syn_sent
# Для защиты от syn флуда
echo 1 > /proc/sys/net/ipv4/tcp_syncookies
# Увеличиваем размер backlog очереди
echo 1280 > /proc/sys/net/ipv4/tcp_max_syn_backlog
# Число начальных SYN и SYNACK пересылок для TCP соединения
echo 4 > /proc/sys/net/ipv4/tcp_synack_retries
echo 4 > /proc/sys/net/ipv4/tcp_syn_retries
#Какие порты использовать в качестве локальных TCP и UDP портов
echo "16384 61000" > /proc/sys/net/ipv4/ip_local_port_range
# Сколько секунд ожидать приема FIN до полного закрытия сокета
echo 30 > /proc/sys/net/ipv4/tcp_fin_timeout
# Как часто посылать сообщение о поддержании keep alive соединения
echo 1800 > /proc/sys/net/ipv4/tcp_keepalive_time
# Сколько пакетов проверки keepalive посылать, прежде чем соединение будет закрыто.
echo 2 > /proc/sys/net/ipv4/tcp_keepalive_probes
# Зaпрещаем TCP window scaling
echo 0 > /proc/sys/net/ipv4/tcp_window_scaling
# Запрещаем selective acknowledgements, RFC2018
echo 0 > /proc/sys/net/ipv4/tcp_sack
# Запрещаем TCP timestamps, RFC1323
echo 0 > /proc/sys/net/ipv4/tcp_timestamps
# Уличиваем размер буфера для приема и отправки данных через сокеты.
echo 1048576 > /proc/sys/net/core/rmem_max
echo 1048576 > /proc/sys/net/core/rmem_default
echo 1048576 > /proc/sys/net/core/wmem_max
echo 1048576 > /proc/sys/net/core/wmem_default
# Через какое время убивать соединеие закрытое на нашей стороне
echo 1 > /proc/sys/net/ipv4/tcp_orphan_retries

##########################################################
log "end"
