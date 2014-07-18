#!/bin/bash

#nrpe:
#command[check_turn_connections]=/usr/lib64/nagios/plugins/check_turn_connections.sh
# command:
#$USER1$/check_nrpe -H $HOSTADDRESS$ -t 15 -c check_turn_connections
# service:
# 

WARN="6000"
CRIT="7000"
NETSTAT=`netstat -an |wc -l`

if [ $NETSTAT -gt $CRIT ]; then echo "CRIT: $NETSTAT open connections"; exit 2; fi
if [ $NETSTAT -gt $WARN ]; then echo "WARN: $NETSTAT open connections"; exit 1; fi

echo "Open connections OK: $NETSTAT"; exit 0
