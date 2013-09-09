#!/bin/bash

# проверка на запущенность данного скрипта #
if [[ `ps uax | grep -v grep | grep -c "ssh_connect.sh" 2>/dev/null` != "2" ]]; then
    exit 0;
fi

# поднимаем подключение к хосту с белым ip
while [ true ]; do
    echo "`date +%D\ %T` $0: CONNECTING SSH TO 80.237.70.158" >> /var/log/gate.log
    ssh -N -C svs_operator@80.237.70.158 -p 1786 -R 10254:127.0.0.1:1786 -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oServerAliveInterval=15 -oServerAliveCountMax=3 -oTCPKeepAlive=yes -oExitOnForwardFailure=yes -i "/etc/gate/data/id_rsa_80.237.70.158" 2>/dev/null;
    echo "`date +%D\ %T` $0: DISCONNECT SSH FROM 80.237.70.158" >> /var/log/gate.log
    sleep 30;
done