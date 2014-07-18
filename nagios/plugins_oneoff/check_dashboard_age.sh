#!/bin/bash

#nrpe:
#command[check_dashboard_latency]=/usr/lib64/nagios/plugins/check_dashboard_latency.sh

WARN="1800"
CRIT="3600"

while getopts "c:w:h" ARG; do
        case $ARG in
                c) CRIT=$OPTARG;;
                w) WARN=$OPTARG;;
                h) echo "Usage: $0 -w <time is seconds> -c <time in seconds>"; exit;;
        esac
done

DIFF=$(echo "`date '+%s'` - `stat -c %Y /var/www/dashboard/index.html`" | bc)

if [ $DIFF -gt $CRIT ]; then echo "CRIT: `hostname -s`:/var/www/dashboard/index.html is $DIFF seconds old!"; exit 2; fi
if [ $DIFF -gt $WARN ]; then echo "WARN: `hostname -s`:/var/www/dashboard/index.html is $DIFF seconds old!"; exit 1; fi

echo "File Age OK: $DIFF seconds old"; exit 0
