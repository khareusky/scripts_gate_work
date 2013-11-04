#!/bin/bash
#############################################
source global.sh
conf_file="$path/openvpn/conf/client.conf"
conf_file_first="`ls $regexp_openvpn_files | head -n 1`"
PING="ping -s 1 -W 3 -c 3 -i 4 -n"

#############################################
create_conf_file() {
        conf_file_current="$1"
        echo "#$conf_file_current" > "$conf_file"
        echo "# этот файл изменяется скриптом: $path/`basename $0`" >> "$conf_file"
        echo "" >> "$conf_file"
        echo "###################################" >> "$conf_file"
        echo "# main settings" >> "$conf_file"
        cat "$conf_file_current" | grep -v "^#" | grep "[^[:space:]]" >> "$conf_file"

        sed -i "/script-security/d" "$conf_file"
        sed -i "/route-up/d" "$conf_file"
        sed -i "/down/d" "$conf_file"
        sed -i "/auth-user-pass/d" "$conf_file"

        echo "" >> "$conf_file"
        echo "###################################" >> "$conf_file"
        echo "# additional settings" >> "$conf_file"
        echo "script-security 2" >> "$conf_file"
        echo "http-proxy $proxy_ip $proxy_port $path/openvpn/proxy_accounts" >> "$conf_file"
        echo "http-proxy-retry" >> "$conf_file"
        echo "route-up $path/openvpn_up.sh" >> "$conf_file"
        echo "down $path/openvpn_down.sh" >> "$conf_file"
        echo "auth-user-pass $path/openvpn/data" >> "$conf_file"
        echo "" >> "$conf_file"
        echo "###################################" >> "$conf_file"
}

#############################################
# проверка на запущенность
check_for_relaunching

#############################################
log "first config file: $conf_file_first";
while [ true ]; do
    ip addr show "$openvpn_iface" >/dev/null 2>&1; # проверка на поднятие openvpn интерфейса
    if [[ "$?" == "0" ]]; then
        conf_file_current="`head $conf_file -n 1 | cut -c 2-`"
        log "current config file: $conf_file_current";
        log "start waiting...";
        while [ true ]; do
            ip addr show "$openvpn_iface" >/dev/null 2>&1; # проверка на поднятие openvpn интерфейса
            if [[ $? -ne 0 ]]; then
                break;
            fi
            sleep 10;
        done

        # отключение openvpn
        log "stopped pinging";
        /etc/init.d/openvpn stop >/dev/null 2>&1
        sleep 2;
        killall openvpn >/dev/null 2>&1
    else
        # выбор конф файла
        CONF_NEXT=0;
        if [[ ! -f "$conf_file" ]]; then
            CONF_NEXT="$conf_file_first"
        else
            conf_file_current="`head $conf_file -n 1 | cut -c 2-`"
            for i in $regexp_openvpn_files; do
                if [[ "$CONF_NEXT" == "1" ]]; then
                    CONF_NEXT="$i";
                    break;
                fi
                if [[ "$i" == "$conf_file_current" ]]; then
                    CONF_NEXT=1;
                fi
            done
            if [[ "$CONF_NEXT" == "0" || "$CONF_NEXT" == "1" ]]; then
                CONF_NEXT="$conf_file_first"
            fi
        fi
        log "current config file: $CONF_NEXT";

        # создание своего конф файла
        create_conf_file "$CONF_NEXT"

        # запуск openvpn
        /etc/init.d/openvpn start >/dev/null
        sleep 60;
    fi
done

#############################################
exit 0;
