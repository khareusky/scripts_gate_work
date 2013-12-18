#!/bin/bash
##########################################
# мониторинг пропускной способности внутреннего сетевого интерфейса
source global.sh

if [[ "$1" == "up" || "$1" == "u" ]]; then
    echo stt | iftop -n -N -i eth3 -m 18M -f "net 10.0.0.0/24 or port 3128";
else if [[ "$1" == "log" || "$1" == "l" ]]; then
    tail -c 10000 -f "$log_file";
else if [[ -z "$1" ]]; then
    echo sttt | iftop -n -N -i "$int" -m 18M -f "(src net 10.0.0.0/24 and not dst net 10.0.0.0/8) or (src net 10.0.0.0/24 and dst host 10.0.0.1 and dst port 3128) or (dst net 10.0.0.0/24 and not src net 10.0.0.0/8) or (dst net 10.0.0.0/24 and src host 10.0.0.1 and src port 3128)"
fi fi fi

##########################################
