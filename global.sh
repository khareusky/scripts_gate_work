#!/bin/bash
#############################################
script_name="`basename $0`"
path="/opt/scripts_gate_work"
log_file="/var/log/syslog"
hosts="$path/data/hosts.txt"

int="eth0"
vokzal="tun0"
mybox="eth1"
interz="eth1.52"
ssh_port="1786"

#int_addr="`ip addr show $int | grep inet -m 1 | awk '{print $2}' | cut -d '/' -f1`"
#int_lan="`ip addr show $int | grep inet -m 1 | awk '{print $2}'`"


#############################################
log() {
    ps x | grep -v grep | grep $$ | grep "+" >/dev/null # проверка на интерактивный запуск
    if [[ "$?" == "0" ]]; then
        echo "`date +%D\ %T` $script_name: $@"
    else
        logger -t "$script_name" "$@";
    fi
}

#############################################
check_for_relaunching() {
    pid_file="/tmp/$script_name.pid"
    count=`ps -C $script_name | wc -l 2>/dev/null`;
    if [[ -e "$pid_file" && "$count" -ge 4 ]]; then
        log "script is DOUBLED, it will be exited";
        exit 0;
    else
        echo $$ > $pid_file;
    fi
}

#############################################