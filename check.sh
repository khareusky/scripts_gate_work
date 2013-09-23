#!/bin/bash
#############################################
source /etc/openvpn/global.sh
ip="8.8.8.8"
iface="tun0"
conf_file="/etc/openvpn/client.ovpn"

#############################################
while [ true ]; do
    ip addr show "$iface" >/dev/null 2>&1; # проверка на поднятие openvpn интерфейса
    if [[ "$?" == "0" ]]; then
        log "ping openvpn: START";
        while [ true ]; do
            ping -I "$iface" -c 4 -i 3 "$ip" >/dev/null || break
            sleep 10;
        done

        log "ping openvpn: STOP";
        /etc/init.d/openvpn stop >/dev/null 2>&1
        sleep 2;
    else
        # отключение openvpn
        /etc/init.d/openvpn stop >/dev/null 2>&1
        sleep 2;
        killall openvpn >/dev/null 2>&1

        # выбор следующего конф файла
        CONF_CURRENT="`ls -l $conf_file | awk '{$1=$2=$3=$4=$5=$6=$7=$8=$9=$10=""}1' | cut -c 11- `"
        CONF_NEXT=0
        CONF_FIRST=0
        log "CURRENT: "$CONF_CURRENT;
        for i in /etc/openvpn/confd/*.ovpn ; do
            if [[ "$CONF_FIRST" == "0" ]]; then
                CONF_FIRST="$i";
            fi
            if [[ "$CONF_NEXT" == "1" ]] ; then
                CONF_NEXT="$i";
                break;
            fi
            if [ "$i" == "$CONF_CURRENT" ] ; then
                CONF_NEXT=1;
            fi
        done
        if [ "$CONF_NEXT" == "0" ] ; then
            CONF_NEXT="$CONF_FIRST"
        fi
        if [ "$CONF_NEXT" == "1" ] ; then
            CONF_NEXT="$CONF_FIRST"
        fi
        log "NEXT: "$CONF_NEXT;

        # создание ссылки на следующий конф файл
        rm -f "$conf_file";
        cp -f "$CONF_NEXT" "$conf_file"
        echo "script-security 2" >> "$conf_file"
        echo "route-up /etc/openvpn/up.sh" >> "$conf_file"
        echo "down /etc/openvpn/down.sh" >> "$conf_file"
        echo "log-append /var/log/openvpn.log" >> "$conf_file"

#        ln -f -s "$CONF_NEXT" "$conf_file"

        # запуск
        /etc/init.d/openvpn start >/dev/null
        sleep 120;
    fi
done

#############################################
exit 0;
