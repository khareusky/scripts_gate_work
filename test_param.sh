#!/bin/bash
source /etc/gate/global.sh

#####################################
echo "INTERNAL INTERFACE: $int | `ip addr show $int | grep inet -m 1 | awk '{print $2}'| cut -d '/' -f1` | `ip addr show $int | grep inet -m 1 | awk '{print $2}'`"
echo "WIFI INTERFACE: $wifi | `ip addr show $wifi | grep inet -m 1 | awk '{print $2}'| cut -d '/' -f1` | `ip addr show $wifi | grep inet -m 1 | awk '{print $2}'`"

#####################################