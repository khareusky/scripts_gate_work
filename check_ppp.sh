#!/bin/bash
#########################################################################
# Скрипт для запуска и проверки функционирования PPPoE каналов
#########################################################################
source global.sh
iface="$1"

#########################################################################
kill_ppp() {
    if [[ `ps -eao pid,cmd | grep -v grep | grep -c "/usr/sbin/pppd call $iface"` != "0" ]]; then
        poff "$iface" >/dev/null
        sleep 3;
    fi

    if [[ `ps -eao pid,cmd | grep -v grep | grep -c "/usr/sbin/pppd call $iface"` != "0" ]]; then
        ps -eao pid,cmd | grep "/usr/sbin/pppd call $iface" | grep -v grep | while read i
        do
            i=`echo $i | awk '{printf $1}'`
            kill "$i"
        done
        sleep 2;
    fi

    if [[ `ps -eao pid,cmd | grep -v grep | grep -c "/usr/sbin/pppd call $iface"` != "0" ]]; then
        ps -eao pid,cmd | grep "/usr/sbin/pppd call $iface" | grep -v grep | while read i
        do
            i=`echo $i | awk '{printf $1}'`
            kill -9 "$i"
        done
        sleep 1;
    fi
}

#########################################################################
# проверка на запущенность
if [[ `ps uax | grep -v grep | grep -c "/bin/bash $path/check_ppp.sh $iface" 2>/dev/null` != "2" ]]; then
    log "script is doubled, exit this one";
    exit 0;
fi

#########################################################################
# периодический пинг и проверка подключения
log "start check $iface";
while [ true ]; do
    ip addr show "$iface" 2>/dev/null;
    if [[ "$?" == "0" ]]; then
        log "START ping $iface";
        ip="`ip addr show $iface | grep inet -m 1| awk '{print $4}'| cut -d '/' -f1`"
        while [ true ]; do
            ping -I "$iface" -s 1 -W 1 -c 5 -i 1 -n "$ip" >/dev/null || break;
        done
        log "STOP ping $iface";
        kill_ppp "$iface"
    else
        kill_ppp "$iface"
        pon "$iface" >/dev/null
        sleep 10;
    fi
done

#########################################################################
