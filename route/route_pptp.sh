#!/bin/bash
########################################################################
 ip route add $PPP_REMOTE dev $PPP_IFACE proto kernel scope link  src $PPP_LOCAL table static

########################################################################