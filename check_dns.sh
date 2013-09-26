#!/bin/bash
#############################################
source global.sh

#############################################
# проверка на запущенность #
check_for_relaunching

#############################################
# изначально положение dns сервера на 10.0.0.254
log "restart dns server to 10.0.0.254";
cp -f $path/bind/named.conf.options_10.0.0.254 /etc/bind/named.conf.options
chown bind:bind /etc/bind/named.conf.options
/etc/init.d/bind9 restart >/dev/null

#############################################
# пинг известного ресурса
ip="8.8.8.8";
while [ true ]; do
    $PING $ip >/dev/null 2>&1;
    if [[ "$?" == "0" ]]; then
        log "restart dns server to root servers";
        cp -f $path/bind/named.conf.options_root /etc/bind/named.conf.options
        chown bind:bind /etc/bind/named.conf.options
        /etc/init.d/bind9 restart >/dev/null 2>&1

        log "START ping $ip";
        while [ true ]; do
            $PING $ip >/dev/null 2>&1 || break;
            sleep 10;
        done
        log "STOP ping $ip";

        log "restart dns server to 10.0.0.254";
        cp -f $path/bind/named.conf.options_10.0.0.254 /etc/bind/named.conf.options
        chown bind:bind /etc/bind/named.conf.options
        /etc/init.d/bind9 restart >/dev/null 2>&1
    fi
    sleep 10;
done

#############################################
exit 0;