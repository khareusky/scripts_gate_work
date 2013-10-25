#!/bin/bash
#############################################
source global.sh

log "killing checking script"
killall check_openvpn.sh

log "stop openvpn"
/etc/init.d/openvpn stop

ps aux | grep open





