#!/bin/bash
#############################################
path=$(cd $(dirname $0) && pwd)
tmp="$path/tmp"

if [[ -z $1 ]]; then
    echo "Usage: $0 archive_name";
    exit 0;
fi
archive_name="$1"
echo "path: $path"
echo "archive_name: $archive_name"

#############################################
# ссылки
rm -f /usr/bin/global.sh
ln -f -s $path/global.sh /usr/bin/global.sh
ls -l /usr/bin/global.sh

rm -f /etc/rc.local
ln -f -s $path/rc.local /etc/rc.local
ls -l /etc/rc.local

rm -f /usr/sbin/monitor.sh
ln -f -s $path/monitor.sh /usr/sbin/monitor.sh
ls -l /usr/sbin/monitor.sh

#############################################
# проверка на установку openvpn
if [[ ! -f /etc/init.d/openvpn ]]; then
    echo "WARNING: you must install openvpn-client: apt-get install openvpn"
fi

#############################################
# архивированные данные
mkdir $tmp

# декодирование
gpg -o $tmp/$archive_name.tar.gz -d $path/$archive_name.tar.gz.gpg || exit 1;

# декомпресия и деархифирование
cd $tmp # общий архив
tar -zxf $archive_name.tar.gz -C $tmp/

cp -f .gitconfig /root/ # github config
chmod 600 /root/.gitconfig
ls -l /root/.gitconfig

rm -rf /etc/openvpn # конф файлы openvpn
rm -rf $path/openvpn
tar -zxf openvpn.tar.gz -C $path/
chmod -R 600 $path/openvpn/*
ln -sf $path/openvpn/conf /etc/openvpn
ls -l /etc/openvpn

cp -f named.conf.options /etc/bind/ # dns
chown root:root /etc/bind/named.conf.options
chmod 644 /etc/bind/named.conf.options
ls -l /etc/bind/named.conf.options

rm -rf $path/dante 2>/dev/null # socks
cp -fr dante $path/
ls -lA $path/dante/*

rm -rf $path/squid3 2>/dev/null # squid3
rm -rf /etc/squid3
cp -fr squid3 $path/
ln -sf $path/squid3 /etc/squid3
ls -l /etc/squid3

cp -f interfaces /etc/network/ # network
chown root:root /etc/network/interfaces
chmod 644 /etc/network/interfaces
ls -l /etc/network/interfaces

cp -f crontab /etc/ # crontab
chown root:root /etc/crontab
chmod 644 /etc/crontab
ls -l /etc/crontab
echo "restart cron"
/etc/init.d/cron restart >/dev/null 2>&1

cp -f config.sh $path/ # config.sh
chmod 644 $path/config.sh
ls -l $path/config.sh

# удаление временной папки
cd /
rm -rf $tmp

#############################################
