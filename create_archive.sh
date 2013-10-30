#!/bin/bash
#############################################
source global.sh
tmp="$path/tmp"

echo "Введите имя архива [`hostname`]:"
read archive_name
if [[ -z $archive_name ]]; then
    archive_name="`hostname`"
fi
log "Имя архива: $archive_name";

#############################################
mkdir $tmp

# создание архива
cd $path # конф файлы openvpn
tar zcf $tmp/openvpn.tar.gz openvpn
cd $tmp
tar cf $archive_name.tar openvpn.tar.gz
ls -ld $path/openvpn

cd /root/ # github config
tar rf $tmp/$archive_name.tar .gitconfig
ls -l /root/.gitconfig

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