#!/bin/bash
#############################################
source global.sh
archive_name="data"
tmp="$path/tmp"

#############################################
mkdir $tmp

# создание архива
cd /etc/openvpn # конф файлы openvpn
tar zcf $tmp/openvpn.tar.gz *
cd $tmp
tar cf $archive_name.tar openvpn.tar.gz
ls -lasd /etc/openvpn

cd /root/.ssh # ключ github
tar rf $tmp/$archive_name.tar id_rsa
ls -lsa /root/.ssh/id_rsa

cd $path/bind # dns сервер
tar rf $tmp/$archive_name.tar named.conf.options_root
tar rf $tmp/$archive_name.tar named.conf.options_forward
ls -lsa $path/bind/named.conf.options_root
ls -lsa $path/bind/named.conf.options_forward

cd /etc/network # network
tar rf $tmp/$archive_name.tar interfaces
ls -lsa /etc/network/interfaces

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