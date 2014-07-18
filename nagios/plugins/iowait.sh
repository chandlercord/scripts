#!/bin/bash

#nrpe:
#command[check_iowait]=/usr/lib64/nagios/plugins/iowait.sh
# command:
#$USER1$/check_nrpe -H $HOSTADDRESS$ -t 15 -c check_iowait
# service:
#
# IOW is iowait * 100 to get rid of the float
CRIT=3500
WARN=3000
IOW=`/usr/bin/mpstat 1 1 | tail -1 | /usr/bin/awk '{print $6}'`
IOW2=`/usr/bin/python -c "print $IOW * 100" | /usr/bin/awk '{print $1 / 1 }'`


if [ $IOW2 -gt $CRIT ]; then echo "CRIT: ${IOW}|iowait=${IOW};$((${WARN}/100));$((${CRIT}/100))"; exit 2; fi
if [ $IOW2 -gt $WARN ]; then echo "WARN: ${IOW}|iowait=${IOW};$((${WARN}/100));$((${CRIT}/100))"; exit 1; fi

echo "OK: ${IOW}|iowait=${IOW};$((${WARN}/100));$((${CRIT}/100))"; exit 0
