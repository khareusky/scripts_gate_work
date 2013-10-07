#!/bin/bash
#############################################
source global.sh
archive_name="data"

#############################################
# создание архива
cd /etc/openvpn # конф файлы openvpn
tar zcf $path/openvpn.tar.gz *
cd $path
tar cf $path/$archive_name.tar openvpn.tar.gz
rm -f $path/openvpn.tar.gz

cd /root/.ssh # ключ github
tar rf $path/$archive_name.tar id_rsa

#############################################
# компресия архива
cd $path
gzip -f $path/$archive_name.tar

#############################################
# криптование архива
if [[ "$?" == "0" ]]; then
    gpg --symmetric --cipher-algo aes256 -o $path/$archive_name.tar.gz.gpg $path/$archive_name.tar.gz
    rm -f $path/$archive_name.tar.gz
fi

#############################################
