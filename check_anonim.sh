#!/bin/bash
#############################################
source /opt/global.sh

#############################################
# проверка на запущенность #
check_for_relaunching

#############################################
# изначально положение dns сервера на 10.0.0.254
log "restart dns server to 10.0.0.254";
cp -f /etc/bind/named.conf.options_10.0.0.254 /etc/bind/named.conf.options
chown bind:bind /etc/bind/named.conf.options
/etc/init.d/bind9 restart >/dev/null

#############################################
# пинг известного ресурса
ip="8.8.8.8";
while [ true ]; do
    ping -s 1 -W 1 -c 3 -i 1 "$ip" >/dev/null;
    if [[ "$?" == "0" ]]; then
        log "restart dns server to root servers";
        cp -f /etc/bind/named.conf.options_root /etc/bind/named.conf.options
        chown bind:bind /etc/bind/named.conf.options
        /etc/init.d/bind9 restart >/dev/null

        log "START ping $ip";
        while [ true ]; do
            ping -s 1 -W 1 -c 3 -i 1 "$ip" >/dev/null || break;
            sleep 10;
        done
        log "STOP ping $ip";

        log "restart dns server to 10.0.0.254";
        cp -f /etc/bind/named.conf.options_10.0.0.254 /etc/bind/named.conf.options
        chown bind:bind /etc/bind/named.conf.options
        /etc/init.d/bind9 restart >/dev/null
    fi
    sleep 10;
done

#############################################
exit 0;