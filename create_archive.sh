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

cd /root/.ssh # ключ github
tar rf $tmp/$archive_name.tar id_rsa

cd /etc/bind # dns сервер
tar rf $tmp/$archive_name.tar named.conf.options

cd /etc/network # network
tar rf $tmp/$archive_name.tar interfaces

#############################################
# компресия архива
cd $tmp
gzip -f $archive_name.tar

#############################################
# криптование архива
if [[ "$?" == "0" ]]; then
    gpg --symmetric --cipher-algo aes256 -o $path/$archive_name.tar.gz.gpg $tmp/$archive_name.tar.gz
fi

#############################################
# удаление временной папки
cd /
rm -rf $tmp

#############################################