#!/bin/bash
#############################################
path=$(cd $(dirname $0) && pwd)
echo "path: $path"

#############################################
# ссылки
rm -f /usr/bin/global.sh
ln -f -s $path/global.sh /usr/bin/global.sh
ls -lsa /usr/bin/global.sh

rm -f /etc/rc.local
ln -f -s $path/rc.local /etc/rc.local
ls -lsa /etc/rc.local

rm -f /usr/sbin/monitor.sh
ln -f -s $path/monitor.sh /usr/sbin/monitor.sh
ls -lsa /usr/sbin/monitor.sh

#############################################
# проверка на установку openvpn
if [[ ! -f /etc/init.d/openvpn ]]; then
    echo "WARNING: you must install openvpn-client: apt-get install openvpn"
fi

#############################################
# архивированные данные
archive_name="data"
tmp="$path/tmp"
mkdir $tmp

# декодирование
gpg -o $tmp/$archive_name.tar.gz -d $path/$archive_name.tar.gz.gpg || exit 1;

# декомпресия и деархифирование
cd $tmp # общий архив
tar -zxvf $archive_name.tar.gz -C $tmp/

cp -f id_rsa /root/.ssh/ # ключ github
chmod 600 /root/.ssh/id_rsa

mkdir /etc/openvpn/ # конф файлы openvpn
tar -zxf openvpn.tar.gz -C /etc/openvpn/
chmod 700 /etc/openvpn
chmod -R 600 /etc/openvpn/*

cp -f named.conf.options /etc/bind/ # bind
chown root:bind /etc/bind/named.conf.options
chmod 644 /etc/bind/named.conf.options

# удаление временной папки
cd /
rm -rf $tmp

#############################################
