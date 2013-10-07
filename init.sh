#!/bin/bash
#############################################
path=$(cd $(dirname $0) && pwd)
echo "path: $path"

rm -f /usr/bin/global.sh
ln -f -s $path/global.sh /usr/bin/global.sh
ls -lsa /usr/bin/global.sh

rm -f /etc/rc.local
ln -f -s $path/rc.local /etc/rc.local
ls -lsa /etc/rc.local

rm -f /usr/sbin/monitor.sh
ln -f -s $path/monitor.sh /usr/sbin/monitor.sh
ls -lsa /usr/sbin/monitor.sh

if [[ ! -f /etc/init.d/openvpn ]]; then
    echo "WARNING: you must install openvpn-client: apt-get install openvpn"
fi

#############################################
# архивированные данные
archive_name="data"

# декодирование
gpg -o $path/$archive_name.tar.gz -d $path/$archive_name.tar.gz.gpg
if [[ "$?" != "0" ]]; then
    exit 1;
fi

# декомпресия и деархифирование
cd $path # общий архив
tar -zxvf $path/$archive_name.tar.gz -C $path/
rm -f $path/$archive_name.tar.gz

mv -f $path/id_rsa /root/.ssh/ # ключ github
chmod 600 /root/.ssh/id_rsa

mkdir /etc/openvpn/ # конф файлы openvpn
tar -zxvf $path/openvpn.tar.gz -C /etc/openvpn/
rm -f openvpn.tar.gz
chmod 700 /etc/openvpn
chmod -R 600 /etc/openvpn/*

#############################################
