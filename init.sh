#!/bin/bash
#############################################
path=$(cd $(dirname $0) && pwd);
echo "path: $path"

rm -f /usr/bin/global.sh
ln -f -s $path/global.sh /usr/bin/global.sh
#cp -f $path/global.sh /usr/bin/global.sh
ls -lsa /usr/bin/global.sh

rm -f /etc/rc.local
ln -f -s $path/rc.local /etc/rc.local
ls -lsa /etc/rc.local

rm -f /etc/ppp/ip-up.d/ppp_up
ln -f -s $path/ppp_up.sh /etc/ppp/ip-up.d/ppp_up
ls -lsa /etc/ppp/ip-up.d/ppp_up

rm -f /etc/ppp/ip-down.d/ppp_down
ln -f -s $path/ppp_down.sh /etc/ppp/ip-down.d/ppp_down
ls -lsa /etc/ppp/ip-down.d/ppp_down

rm -f /etc/squid3
ln -f -s $path/squid3 /etc/squid3
ls -lsa /etc/squid3

rm -f /etc/passwd_squid3
ln -f -s $path/data/passwd_squid3 /etc/passwd_squid3
ls -lsa /etc/passwd_squid3

rm -f /etc/squid3/squid3_first_channel_src.txt
ln -f -s $path/data/squid3_first_channel_src.txt /etc/squid3/squid3_first_channel_src.txt
ls -lsa /etc/squid3/squid3_first_channel_src.txt

rm -f /etc/squid3/squid3_second_channel_src.txt
ln -f -s $path/data/squid3_second_channel_src.txt /etc/squid3/squid3_second_channel_src.txt
ls -lsa /etc/squid3/squid3_second_channel_src.txt

rm -f /etc/squid3/squid3_third_channel_src.txt
ln -f -s $path/data/squid3_third_channel_src.txt /etc/squid3/squid3_third_channel_src.txt
ls -lsa /etc/squid3/squid3_third_channel_src.txt

rm -f /etc/squid3/squid3_first_channel_dst.txt
ln -f -s $path/data/squid3_first_channel_dst.txt /etc/squid3/squid3_first_channel_dst.txt
ls -lsa /etc/squid3/squid3_first_channel_dst.txt

rm -f /etc/squid3/squid3_second_channel_dst.txt
ln -f -s $path/data/squid3_second_channel_dst.txt /etc/squid3/squid3_second_channel_dst.txt
ls -lsa /etc/squid3/squid3_second_channel_dst.txt


rm -f /etc/squid3/squid3_third_channel_dst.txt
ln -f -s $path/data/squid3_third_channel_dst.txt /etc/squid3/squid3_third_channel_dst.txt
ls -lsa /etc/squid3/squid3_third_channel_dst.txt

rm -f /etc/squid3/squid3_forth_channel_dst.txt
ln -f -s $path/data/squid3_forth_channel_dst.txt /etc/squid3/squid3_forth_channel_dst.txt
ls -lsa /etc/squid3/squid3_forth_channel_dst.txt

rm -f /etc/ppp/chap-secrets.txt
ln -f -s $path/data/chap-secrets.txt /etc/ppp/chap-secrets
ls -lsa /etc/ppp/chap-secrets

rm -f /etc/iproute2/rt_tables
ln -f -s $path/data/rt_tables /etc/iproute2/rt_tables
ls -lsa /etc/iproute2/rt_tables

rm -f /etc/ppp/peers/ppp101
ln -f -s $path/data/settings_ppp101.txt /etc/ppp/peers/ppp101
ls -lsa /etc/ppp/peers/ppp101

rm -f /etc/ppp/peers/ppp102
ln -f -s $path/data/settings_ppp102.txt /etc/ppp/peers/ppp102
ls -lsa /etc/ppp/peers/ppp102

rm -f /etc/ppp/peers/ppp103
ln -f -s $path/data/settings_ppp103.txt /etc/ppp/peers/ppp103
ls -lsa /etc/ppp/peers/ppp103

rm -f /usr/sbin/monitor.sh
ln -f -s $path/monitor.sh /usr/sbin/monitor.sh
ls -lsa /usr/sbin/monitor.sh

#############################################
