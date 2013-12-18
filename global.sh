#!/bin/bash
#########################################################################
int="eth3"
ext1="eth0"
ext2="eth1"
ext3="eth2"
ppp1="ppp101"
ppp2="ppp102"
ppp3="ppp103"

script_name="`basename $0`"
path="/opt/scripts_gate_work"
log_file="/var/log/syslog"

int_addr="`ip addr show $int | grep inet -m 1 | awk '{print $2}' | cut -d '/' -f1`"
int_lan="`ip addr show $int | grep inet -m 1 | awk '{print $2}'`"

hosts_file="$path/data/hosts.txt"
hosts_params="ip proxy nat channel rate_down rate_up log comment"

#########################################################################
log() {
    ps x | grep -v grep | grep $$ | grep "+" >/dev/null # проверка на интерактивный запуск
    if [[ "$?" == "0" ]]; then
        echo -e "`date +%D\ %T` $script_name: $@"
    else
        logger -t "$script_name" "$@";
    fi
}

#########################################################################
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

#########################################################################
