
source /etc/gate/global.sh

while read temp; do
 ip rule del prio "`echo -n ppp103 | tail -c 3`"
done < <(ip rule ls | grep ^"`echo -n ppp103 | tail -c 3`:")