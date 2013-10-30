#!/bin/bash
#############################################
source global.sh
archive_name="data"
tmp="$path/tmp"

#############################################
mkdir $tmp

# создание архива
cd $path # конф файлы openvpn
tar zcf $tmp/openvpn.tar.gz openvpn
cd $tmp
tar cf $archive_name.tar openvpn.tar.gz
ls -ld $path/openvpn

cd /root/.ssh # ключ github
tar rf $tmp/$archive_name.tar id_rsa
ls -l /root/.ssh/id_rsa

cd /etc/bind # dns сервер
tar rf $tmp/$archive_name.tar named.conf.options
ls -l /etc/bind/named.conf.options

cd $path # dante
tar rf $tmp/$archive_name.tar dante
ls -lA $path/dante/*

cd $path # squid3
tar rf $tmp/$archive_name.tar squid3
ls -lA $path/squid3/*

cd /etc/network # network
tar rf $tmp/$archive_name.tar interfaces
ls -l /etc/network/interfaces

cd /etc/iproute2 # rt_tables
tar rf $tmp/$archive_name.tar rt_tables
ls -l /etc/iproute2/rt_tables

cd /etc # crontab
tar rf $tmp/$archive_name.tar crontab
ls -l /etc/crontab

#############################################
# компресия архива
cd $tmp
gzip -f $archive_name.tar

#############################################
# криптование архива
if [[ "$?" == "0" ]]; then
    rm -f $path/$archive_name.tar.gz.gpg
    gpg --symmetric --yes --cipher-algo aes256 -o $path/$archive_name.tar.gz.gpg $tmp/$archive_name.tar.gz
fi

#############################################
# удаление временной папки
log "remove temp dir"
cd /
rm -rf $tmp

#############################################