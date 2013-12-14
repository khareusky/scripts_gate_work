#!/bin/bash
############################################################
# Скрипт предназначен для предоставления удаленного доступа к данному серверу
source global.sh

############################################################
# SSH REVERS
$path/ssh_remote_access.sh "80.237.70.158:10254 127.0.0.1:22" "ssh -N -C svs_operator@80.237.70.158 -p 1786 -R 10254:127.0.0.1:22 -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oServerAliveInterval=15 -oServerAliveCountMax=3 -oTCPKeepAlive=yes -oExitOnForwardFailure=yes -i $path/data/id_rsa_80.237.70.158 2>/dev/null"&
$path/ssh_remote_access.sh "80.237.70.158:22345 10.0.0.233:3389" "ssh -N -C svs_operator@80.237.70.158 -p 1786 -R 22345:10.0.0.233:3389 -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oServerAliveInterval=15 -oServerAliveCountMax=3 -oTCPKeepAlive=yes -oExitOnForwardFailure=yes -i $path/data/id_rsa_80.237.70.158 2>/dev/null"&

exit 0;
############################################################
while read src_ip src_port dst_user dst_ip dst_port dst_key temp; do
    $path/ssh_remote_access.sh "$dst_ip:$dst_port $src_ip:$src_port" "ssh -N -C $dst_user@$dst_ip -p 1786 -R 10254:127.0.0.1:22 -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oServerAliveInterval=15 -oServerAliveCountMax=3 -oTCPKeepAlive=yes -oExitOnForwardFailure=yes -i $path/data/id_rsa_80.237.70.158 2>/dev/null"&
done < <(cat $path/data/ssh_remote_access.txt | grep -v "^#" | grep "[^[:space:]]")

############################################################