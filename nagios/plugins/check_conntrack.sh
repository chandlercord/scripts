#!/bin/bash

#nrpe:
#command[check_conntrak]=/usr/lib64/nagios/plugins/check_conntrack.sh
#command:
#$USER1$/check_nrpe -H $HOSTADDRESS$ -t 15 -c check_conntrack

USAGE="Usage:\t \$ bash $0 -w <WARN %> -c <CRIT %>\nExample: \$ bash $0 -w 75 -c 90"

if [ $# == 0 ]; then
  echo -e $USAGE
  exit 1
fi

while getopts "c:w:h" ARG; do
  case $ARG in
    w) WARN=$OPTARG;;
    c) CRIT=$OPTARG;;
    h) echo -e $USAGE; exit 1;;
  esac
done

if [ `find /proc/sys -name *conntrack_count | wc -l` -eq "0" ]; then
  echo "CRIT: Firewall is not running!"; exit 2; 
fi

COUNT_FILE=`find /proc/sys -name *conntrack_count | head -n 1`
MAX_FILE=`find /proc/sys -name *conntrack_max | head -n 1`
COUNT=`cat $COUNT_FILE | head -n 1`
MAX=`cat $MAX_FILE | head -n 1 `
WARN=`expr $MAX \* $1 \/ 100`
CRIT=`expr $MAX \* $2 \/ 100`

if [ $COUNT -gt $CRIT ]; then echo "CRIT: $COUNT Connections!"; exit 2; fi
if [ $COUNT -gt $WARN ]; then echo "WARN: $COUNT Connections!"; exit 1; fi

echo "OK: $COUNT connections."; exit 0
