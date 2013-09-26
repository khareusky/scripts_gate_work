#!/bin/bash
#############################################
source /opt/global.sh
check_ip="217.175.26.230"
conf_file="/etc/openvpn/client.conf"
conf_file_first="`ls /etc/openvpn/*.ovpn | head -n 1`"

#############################################
create_conf_file() {
        conf_file_current="$1"
        echo "#$conf_file_current" > "$conf_file"
        echo "# этот файл изменяется скриптом: `basename $0`" >> "$conf_file"
        echo "" >> "$conf_file"
        echo "###################################" >> "$conf_file"
        echo "# main settings" >> "$conf_file"
        cat "$conf_file_current" | grep -v "^#" | grep "[^[:space:]]" >> "$conf_file"

        sed -i "/script-security/d" "$conf_file"
        sed -i "/route-up/d" "$conf_file"
        sed -i "/down/d" "$conf_file"
        sed -i "/link-mtu/d" "$conf_file"
        sed -i "/auth-user-pass/d" "$conf_file"

        echo "" >> "$conf_file"
        echo "###################################" >> "$conf_file"
        echo "# additional settings" >> "$conf_file"
        echo "script-security 2" >> "$conf_file"
        echo "route-up $path/openvpn_up.sh" >> "$conf_file"
        echo "down $path/openvpn_down.sh" >> "$conf_file"
        echo "link-mtu 1576" >> "$conf_file"
        echo "auth-user-pass data" >> "$conf_file"
        echo "" >> "$conf_file"
        echo "###################################" >> "$conf_file"
}

#############################################
# проверка на запущенность
check_for_relaunching

#############################################
log "FIRST: $conf_file_first";
while [ true ]; do
    ip addr show "$openvpn_iface" >/dev/null 2>&1; # проверка на поднятие openvpn интерфейса
    if [[ "$?" == "0" ]]; then
        log "ping openvpn: START";
        while [ true ]; do
            ping -I "$openvpn_iface" -c 4 -i 3 "$check_ip" >/dev/null 2>&1 || break
            sleep 10;
        done

        log "ping openvpn: STOP";
        /etc/init.d/openvpn stop >/dev/null 2>&1
        sleep 2;
    else
        # отключение openvpn
        /etc/init.d/openvpn stop >/dev/null 2>&1
        sleep 2;
        killall openvpn >/dev/null 2>&1

        # выбор конф файла
        CONF_NEXT=0;
        if [[ ! -f "$conf_file" ]]; then
            CONF_NEXT="$conf_file_first"
        else
            conf_file_current="`head $conf_file -n 1 | cut -c 2-`"
            log "CURRENT: $conf_file_current";

            for i in /etc/openvpn/*.ovpn; do
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
        log "NEXT: $CONF_NEXT";

        # создание своего конф файла
        create_conf_file "$CONF_NEXT"

        # запуск openvpn
        /etc/init.d/openvpn start >/dev/null
        sleep 60;
    fi
done

#############################################
exit 0;
