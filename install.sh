#!/bin/bash
#############################################
path=$(cd $(dirname $0) && pwd) # определение пути нахождение настроек
tmp="$path/tmp" # директория для временных файлов

#############################################
# проверка на входные данные
if [[ -z $1 ]]; then
    echo "Usage: $0 config_archive_name";
    exit 0;
fi
archive_name="$1"
echo "config path: $path"
echo "config_archive_name: $archive_name"

#############################################
# установка ссылок на скрипты
echo "create links to scripts"
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
# декодирование, декомпресия, деархифирование настроек
echo "decrypt archive with data"
mkdir $tmp
gpg -o $tmp/$archive_name.tar.gz -d $path/$archive_name.tar.gz.gpg || echo ERROR!!! && rm -rf $tmp && exit 1;
tar -zxf $archive_name.tar.gz -C $tmp/

#############################################
# копирование настроек
echo "copy /etc and /data"
rm -rf $path/etc 2>/dev/null
rm -rf $path/data 2>/dev/null
cp -f $tmp/etc $path/
cp -f $tmp/data $path/
ls -lA $path/etc
ls -lA $path/data

#############################################
# замещение настроек
echo "replace configs"
ln -f $path/etc/named.conf.options /etc/bind/ # dns server
chown root:root /etc/bind/named.conf.options
chmod 644 /etc/bind/named.conf.options
/etc/init.d/bind9 restart

ln -f $path/etc/danted.conf /etc/ # socks server
/etc/init.d/danted restart

rm -rf /etc/squid3 # squid3
ln -sf $path/etc/squid3 /etc/squid3
ls -l /etc/squid3
/etc/init.d/squid3 reload

ln -sf $path/etc/crontab /etc/crontab # crontab
ls -l /etc/crontab
/etc/init.d/cron restart

ln -sf $path/etc/network/interfaces /etc/network/interfaces # network
ls -l /etc/network/interfaces

cp -f $tmp/.gitconfig /root/ # github config
chmod 600 /root/.gitconfig
ls -l /root/.gitconfig

#############################################
# удаление временной папки
cd /
rm -rf $tmp

#############################################
echo "end"