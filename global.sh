#!/bin/bash
#############################################
path="/opt/"
int_iface="eth0"
openvpn_iface="tun0"
log_file="/var/log/syslog"
PING="ping -s 1 -W 3 -c 3 -i 4 -n"

#############################################
log() {
    script_name="`basename $0`"
    ps x | grep -v grep | grep $$ | grep "+" >/dev/null # проверка на интерактивный запуск
    if [[ "$?" == "0" ]]; then
        echo "`date +%D\ %T` $script_name: $@"
    else
        logger -t "$script_name" "$@";
    fi
}

#############################################
check_for_relaunching() {
    script_name="`basename $0`"
    if [[ `ps uax | grep -v grep | grep -c "$script_name" 2>/dev/null` != "2" ]]; then
        log "script is doubled, exit this one";
        exit 0;
    fi
}
#############################################
