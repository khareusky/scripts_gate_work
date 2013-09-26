#!/bin/bash --verbose
#############################################
path=$(cd $(dirname $0) && pwd);

# первоначальная инициализация скриптов
rm -f /usr/bin/global.sh
ln -f -s $path/global.sh /usr/bin/global.sh

rm -f /etc/rc.local
ln -f -s $path/rc.local /etc/rc.local

rm -f -R /etc/squid3
ln -f -s $path/squid3 /etc/squid3

#############################################
