#!/bin/bash
#############################################
source global.sh

#############################################
# проверка на запущенность
check_for_relaunching

#############################################
# проверка на поднятие openvpn интерфейса
ip addr show "$openvpn_iface" >/dev/null 2>&1;
if [[ $? -eq 0 ]]; then
    log "exit $script_name"
    exit 0;
fi

#############################################
# начальная установка состояния системы
log "set up initial state"
initial_state="0"
ping -s 1 -W 2 -c 1 -i 1 -n -I "$int_iface" "$redirect_ip" >/dev/null 2>&1
if [[ "$?" == "0" ]]; then
    $path/start_redirect.sh
    initial_state="1"
else
    $path/stop_all.sh
    initial_state="0"
fi

#############################################
# периодическая проверка на активность второго vpn
log "start checking $redirect_ip"
while [ true ]; do
    # проверка на поднятие openvpn интерфейса
    ip addr show "$openvpn_iface" >/dev/null 2>&1;
    if [[ $? -eq 0 ]]; then
        log "stop checking $redirect_ip"
        log "exit $script_name"
        exit 0;
    fi

    # проверка второго vpn
    ping -s 1 -W 2 -c 2 -i 1 -n -I "$int_iface" "$redirect_ip" >/dev/null 2>&1
    if [[ "$?" -eq 0 && "$initial_state" -eq "0" ]]; then
        $path/start_redirect.sh
        initial_state="1"
    fi
    if [[ $? -ne 0 && "$initial_state" -eq "1" ]]; then
        $path/stop_all.sh
        initial_state="0"
    fi

    sleep 10;
done

#############################################


