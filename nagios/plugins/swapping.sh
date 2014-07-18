#!/bin/bash

#nrpe:
#command[check_swapping]=/usr/lib64/nagios/plugins/swapping.sh
# command:
#$USER1$/check_nrpe -H $HOSTADDRESS$ -t 15 -c check_swapping
# service:
# 
if [ -f /usr/bin/vmstat ] 
  then
  SWAPIN=`/usr/bin/vmstat | /bin/awk 'END {print \$7}'`
  SWAPOUT=`/usr/bin/vmstat | /bin/awk 'END {print \$8}'`
  else echo UNKNOWN:  Cannot find vmstat; exit 3;
fi

# swap is in Kb per second swapped in
CRIT=10240 # 1Gb
WARN=5120 #512M

if [ $SWAPIN -gt $CRIT ]; then echo CRIT: swap in: $SWAPIN; exit 2; fi
if [ $SWAPOUT -gt $CRIT ]; then echo CRIT: swap out: $SWAPOUT; exit 2; fi
if [ $SWAPIN -gt $WARN ]; then echo WARN: swap in: $SWAPIN; exit 1; fi
if [ $SWAPOUT -gt $WARN ]; then echo WARN: swap out: $SWAPOUT; exit 1; fi

echo Swapping OK: swap in: $SWAPIN  swap out: $SWAPOUT; exit 0
