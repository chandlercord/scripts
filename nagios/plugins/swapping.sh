#!/bin/bash

#command[check_swapping]=/usr/lib64/nagios/plugins/swapping.sh
#$USER1$/check_nrpe -H $HOSTADDRESS$ -t 15 -c check_swapping

. /usr/lib64/nagios/plugins/utils.sh

# swap is in Kb per second swapped in
CRIT=10240 # 1Gb
WARN=5120 #512M

USAGE="Checks virtual memory swappiness in KB per second.\nUsage: $0 -c <Crit value in KB> -w <Warn value in KB>\n\nOptions:\n\t-w\t${WARN}\t#default\n\t-c\t${CRIT}\t#default\n\t-d\t<Use default values>"

if [ $# == 0 ]; then
  echo -e $USAGE
  exit 1
fi

while getopts "c:w:dh" ARG; do
  case $ARG in
    w) WARN=$OPTARG;;
    c) CRIT=$OPTARG;;
    d) DEFAULT="TRUE";;
    h) echo -e $USAGE; exit 1;;
  esac
done

if [ -f /usr/bin/vmstat ]; then
  SWAPIN=`/usr/bin/vmstat | /bin/awk 'END {print \$7}'`
  SWAPOUT=`/usr/bin/vmstat | /bin/awk 'END {print \$8}'`
else
  echo "UNKNOWN: Cannot find vmstat"; exit 3;
fi

if [ $SWAPIN -gt $CRIT ]; then echo CRIT: swap in: $SWAPIN; exit 2; fi
if [ $SWAPOUT -gt $CRIT ]; then echo CRIT: swap out: $SWAPOUT; exit 2; fi
if [ $SWAPIN -gt $WARN ]; then echo WARN: swap in: $SWAPIN; exit 1; fi
if [ $SWAPOUT -gt $WARN ]; then echo WARN: swap out: $SWAPOUT; exit 1; fi

echo "Swapping OK: swap in: $SWAPIN. swap out: $SWAPOUT.; exit 0
