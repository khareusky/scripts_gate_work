#!/bin/bash
#############################################
path=$(cd $(dirname $0) && pwd)
echo "path: $path"

rm -f /usr/bin/global.sh
ln -f -s $path/global.sh /usr/bin/global.sh
ls -lsa /usr/bin/global.sh

rm -f /etc/rc.local
ln -f -s $path/rc.local /etc/rc.local
ls -lsa /etc/rc.local

rm -f -R /etc/squid3
ln -f -s $path/squid3 /etc/squid3
ls -lsa /etc/squid3

if [[ ! -f /etc/init.d/openvpn ]]; then
    echo "WARNING: you must install openvpn-client: apt-get install openvpn"
fi

#############################################
