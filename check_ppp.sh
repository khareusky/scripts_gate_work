#!/bin/bash

log() {
    echo "`date +%D\ %T` $@" >> /etc/gate/logs/ppp.log;
}

kill_ppp() {
    if [[ `ps -eao pid,cmd | grep -v grep | grep -c "/usr/sbin/pppd call $iface"` != "0" ]]; then
        log "poff $iface"
        poff "$iface" >/dev/null
        sleep 1;
    fi

    if [[ `ps -eao pid,cmd | grep -v grep | grep -c "/usr/sbin/pppd call $iface"` != "0" ]]; then
        log "weak stop $iface"
        ps -eao pid,cmd | grep "/usr/sbin/pppd call $iface" | grep -v grep | while read i
        do
            i=`echo $i | awk '{printf $1}'`
            kill "$i"
        done
        sleep 1
    fi

    if [[ `ps -eao pid,cmd | grep -v grep | grep -c "/usr/sbin/pppd call $iface"` != "0" ]]; then
        log "force stop $iface"
        ps -eao pid,cmd | grep "/usr/sbin/pppd call $iface" | grep -v grep | while read i
        do
            i=`echo $i | awk '{printf $1}'`
            kill -9 "$i"
        done
        sleep 1
    fi
}

iface="$1"

# проверка на запущенность #
if [[ `ps uax | grep -v grep | grep -c "/bin/bash /etc/gate/check_ppp.sh $iface" 2>/dev/null` != "2" ]]; then
    log "checking of the $iface is doubled"
    exit 0
fi

while [ true ];
do
    if [[ `ip addr show "$iface" 2>/dev/null` ]]; then
        log "ping $iface: START";
        ip="`ip addr show $iface | grep inet -m 1| awk '{print $4}'| cut -d '/' -f1`"
        while [ true ]; do
            ping -I "$iface" -s 1 -W 1 -c 5 -i 1 "$ip" >/dev/null || break;
        done
        log "ping $iface: STOP";
        kill_ppp "$iface"
    else
        kill_ppp "$iface"
        log "pon $iface"
        pon "$iface" >/dev/null
        sleep 4
    fi
done

exit 0;
