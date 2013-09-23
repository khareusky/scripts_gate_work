#!/bin/bash
#############################################
log() {
        ps x | grep -v grep | grep $$ | grep "+" >/dev/null # проверка на интерактивный запуск
        if [[ "$?" == "0" ]]; then
            echo "`date +%D\ %T` `basename $0`: $@"
        else
            logger -t "`basename $0`" "$@";
        fi
}

#############################################
