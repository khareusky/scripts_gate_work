#!/bin/bash
#############################################
path=$(cd $(dirname $0) && pwd)
tmp="$path/tmp"

#############################################
echo -n "Введите имя архива [`hostname`]: "
read archive_name
if [[ -z $archive_name ]]; then
    archive_name="`hostname`"

fi
echo "path: $path"
echo "temp path: $tmp"
echo "config_archive_name: $archive_name"

#############################################
# создание архива
echo "create archive"
mkdir $tmp
cd $path

tar zcf $tmp/etc.tar.gz etc
tar zcf $tmp/data.tar.gz data
cd $tmp
tar cf $archive_name.tar etc.tar.gz
tar rf $archive_name.tar data.tar.gz
ls -ld $path/etc
ls -ld $path/data

#############################################
# компресия архива
echo "compression archive"
cd $tmp
gzip -f $archive_name.tar

#############################################
# криптование архива
echo "crypt archive"
if [[ "$?" == "0" ]]; then
    rm -f $path/$archive_name.tar.gz.gpg
    gpg --symmetric --yes --cipher-algo aes256 -o $path/$archive_name.tar.gz.gpg $tmp/$archive_name.tar.gz
fi

#############################################
# удаление временной папки
echo "remove temp dir"
cd /
rm -rf $tmp

#############################################
echo "end"