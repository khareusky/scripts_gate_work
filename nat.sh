#!/bin/bash
##########################################################################################
#
# - проброс портов для внешнего доступа из сети Интернет
# - натирование транзитного траффика с ЛВС в сеть Интернет
#
##########################################################################################
 int=eth3
 ppp1=ppp101
 ppp2=ppp102
 ppp3=ppp103
 PPP_LOCAL1="`ip addr show $ppp1|grep inet -m 1| awk '{print $2}'| cut -d '/' -f1`"
 PPP_REMOTE1="`ip addr show $ppp1|grep inet -m 1| awk '{print $4}'| cut -d '/' -f1`"
 PPP_LOCAL2="`ip addr show $ppp2|grep inet -m 1| awk '{print $2}'| cut -d '/' -f1`"
 PPP_REMOTE2="`ip addr show $ppp2|grep inet -m 1| awk '{print $4}'| cut -d '/' -f1`"
 PPP_LOCAL3="`ip addr show $ppp3|grep inet -m 1| awk '{print $2}'| cut -d '/' -f1`"
 PPP_REMOTE3="`ip addr show $ppp3|grep inet -m 1| awk '{print $4}'| cut -d '/' -f1`"

### DNAT ##################################################################################
 iptables --table nat --flush

### NAT PREROUTING ###
 iptables -t nat -F PREROUTING
 while read ip_src ip_dst dport1 dport2 iface temp
 do
    if [ "$iface" == "ppp" ]; then
        iptables -t nat -A PREROUTING -i "$ppp1" -p tcp -m tcp --dport $dport1 -j DNAT --to-destination "$ip_dst":"$dport2"
        iptables -t nat -A PREROUTING -i "$ppp2" -p tcp -m tcp --dport $dport1 -j DNAT --to-destination "$ip_dst":"$dport2"
        iptables -t nat -A PREROUTING -i "$ppp3" -p tcp -m tcp --dport $dport1 -j DNAT --to-destination "$ip_dst":"$dport2"
    fi
    if [ "$iface" == "int" ]; then
        iptables -t nat -A PREROUTING -s "$ip_src" -i "$int" -p tcp -m tcp --dport $dport1 -j DNAT --to-destination "$ip_dst":"$dport2"
    fi
    if [ "$iface" == "pptp" ]; then
        iptables -t nat -A PREROUTING -s "$ip_src" -p tcp -m tcp --dport $dport1 -j DNAT --to-destination "$ip_dst":"$dport2"
    fi
 done < <(cat /etc/gate/data/list_of_dnat.txt | grep -v "^#" | grep "[^[:space:]]")

### MANGLE PREROUTING ###
 iptables -t mangle -F PREROUTING
 while read ip_src ip_dst dport1 dport2 iface temp
 do
     iptables -t mangle -A PREROUTING -i "$ppp1" -p tcp --dport "$dport1" -m state --state NEW -j CONNMARK --set-mark 0x1
     iptables -t mangle -A PREROUTING -i "$ppp2" -p tcp --dport "$dport1" -m state --state NEW -j CONNMARK --set-mark 0x2
     iptables -t mangle -A PREROUTING -i "$ppp3" -p tcp --dport "$dport1" -m state --state NEW -j CONNMARK --set-mark 0x3
 done < <(cat /etc/gate/data/list_of_dnat.txt | grep -v "^#" | grep "[^[:space:]]")
 iptables -t mangle -A PREROUTING -j CONNMARK --restore-mark

### FILTER FORWARD ###
 iptables -F FORWARD_DNAT
 while read ips ipd dport1 dport2 temp
 do
    iptables -A FORWARD_DNAT -o $int -d $ipd -p tcp --dport "$dport2" -m state --state NEW -j ACCEPT
    iptables -A FORWARD_DNAT -i $int -s $ipd -p tcp --sport $dport2 -m state --state NEW -j ACCEPT
 done < <(cat /etc/gate/data/list_of_dnat.txt | grep -v "^#" | grep "[^[:space:]]")

##########################################################################################
### SNAT ###
 ### ACCESS ###
 iptables -F FORWARD_SNAT
 while read name server passwd ip iface proxy nat pptp channel rate1 rate2 log comment
 do
    if [ "$nat" == "1" ]; then
        iptables -A FORWARD_SNAT -s $ip -j ACCEPT
    fi
 done < <(cat /etc/gate/data/chap-secrets | grep -v "^#" | grep "[^[:space:]]")

 ### NAT ###
 iptables -t nat -F POSTROUTING
 iptables -t nat -A POSTROUTING -s 10.0.3.0/24 -o eth3 -j SNAT --to-source 10.0.0.254
 if [ "$PPP_REMOTE1" != "" ]; then
    iptables -t nat -A POSTROUTING ! -s "$PPP_LOCAL1" -o "$ppp1" -j SNAT --to-source "$PPP_LOCAL1"
 fi
 if [ "$PPP_REMOTE2" != "" ]; then
    iptables -t nat -A POSTROUTING ! -s "$PPP_LOCAL2" -o "$ppp2" -j SNAT --to-source "$PPP_LOCAL2"
 fi
 if [ "$PPP_REMOTE3" != "" ]; then
    iptables -t nat -A POSTROUTING ! -s "$PPP_LOCAL3" -o "$ppp3" -j SNAT --to-source "$PPP_LOCAL3"
 fi

##########################################################################################
 iptables-save
