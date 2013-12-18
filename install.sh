#!/bin/bash
#############################################
path=$(cd $(dirname $0) && pwd) # определение пути нахождение настроек
tmp="$path/tmp" # директория для временных файлов

#############################################
# проверка на входные данные
if [[ -z $1 ]]; then
    #echo "Usage: $0 config_archive_name";
    #exit 0;
    archive_name="`hostname`"
else
    archive_name="$1"
fi
echo "path: $path"
echo "temp path: $tmp"
echo "config_archive_name: $path/$archive_name.tar.gz.gpg"

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

rm -f /etc/ppp/ip-up.d/ppp_up
ln -f -s $path/ppp_up.sh /etc/ppp/ip-up.d/ppp_up
ls -lsa /etc/ppp/ip-up.d/ppp_up

rm -f /etc/ppp/ip-down.d/ppp_down
ln -f -s $path/ppp_down.sh /etc/ppp/ip-down.d/ppp_down
ls -lsa /etc/ppp/ip-down.d/ppp_down

#############################################
# декодирование, декомпресия, деархифирование настроек
echo "decrypt archive with data"
mkdir $tmp
gpg -o $tmp/$archive_name.tar.gz -d $path/$archive_name.tar.gz.gpg || ( echo "ERROR!!!"; rm -rf $tmp; exit 1; )
tar -zxf $tmp/$archive_name.tar.gz -C $tmp/

#############################################
# копирование настроек
echo "copy /etc and /data"
rm -rf $path/etc 2>/dev/null
rm -rf $path/data 2>/dev/null
tar -zxf $tmp/etc.tar.gz -C $path/
tar -zxf $tmp/data.tar.gz -C $path/
ls -ld $path/etc
ls -ld $path/data

#############################################
# замещение настроек
echo "replace configs"
ln -f $path/etc/bind/named.conf.options /etc/bind/ # dns server
chown root:root /etc/bind/named.conf.options
chmod 644 /etc/bind/named.conf.options
/etc/init.d/bind9 restart

ln -f $path/etc/danted.conf /etc/ # socks server
ls -l /etc/danted.conf
/etc/init.d/danted restart

ln -sf $path/etc/squid3 /etc/squid3 # squid
ls -l /etc/squid3
/etc/init.d/squid3 reload

ln -sf $path/etc/ppp/chap-secrets /etc/ppp/chap-secrets # ppp
ln -sf $path/etc/ppp/peers /etc/ppp/peers
ls -l /etc/ppp/chap-secrets
ls -ld /etc/ppp/peers/

ln -sf $path/etc/iproute2/rt_tables /etc/iproute2/rt_tables # rt_tables
ls -l /etc/iproute2/rt_tables

ln -sf $path/etc/crontab /etc/crontab # crontab
ls -l /etc/crontab
/etc/init.d/cron restart

ln -sf $path/etc/network/interfaces /etc/network/interfaces # network
ls -l /etc/network/interfaces

ln -sf $path/etc/.gitconfig /root/.gitconfig # git config
chmod 600 /root/.gitconfig
ls -l /root/.gitconfig

#############################################
# удаление временной папки
cd /
rm -rf $tmp

#############################################
echo "end"