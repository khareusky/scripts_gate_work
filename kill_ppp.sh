#!/bin/bash
#############################################
source global.sh
iface="$1"

#############################################
if [[ -z $1 ]]; then
    echo "Usage: $0 ppp_iface";
    exit 0;
fi

#############################################
id=`ps -eao pid,cmd | grep -v grep | grep "check_ppp.sh $iface" | awk '{printf $1}'`
log "killing checking script ppp: $id"
kill "$id"

#############################################
log "stop pptpd"
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

#############################################
log "\n`ps aux | grep ppp`"





