#!/bin/bash --verbose
#############################################
path=$(cd $(dirname $0) && pwd);

# первоначальная инициализация скриптов
rm -f /usr/bin/global.sh
ln -f -s $path/global.sh /usr/bin/global.sh

rm -f /etc/rc.local
ln -f -s $path/rc.local /etc/rc.local

#############################################
