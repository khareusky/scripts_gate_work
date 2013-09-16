
source /etc/gate/global.sh

PPP_IFACE="ppp103"
PPP_LOCAL="193.34.34.34"
 while read temp; do
    ip rule del prio "`echo -n $PPP_IFACE | tail -c 3`"
 done < <(ip rule ls | grep ^"`echo -n $PPP_IFACE | tail -c 3`:")
 ip rule add from "$PPP_LOCAL" table "$PPP_IFACE" prio "`echo -n $PPP_IFACE | tail -c 3`"

exit 0;
while read temp; do
 ip rule del prio "`echo -n ppp103 | tail -c 3`"
done < <(ip rule ls | grep ^"`echo -n ppp103 | tail -c 3`:")