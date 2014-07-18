#!/bin/bash

#nrpe:
#command[check_noconntrak]=/usr/lib64/nagios/plugins/check_noconntrack.sh
#command:
#$USER1$/check_nrpe -H $HOSTADDRESS$ -t 15 -c check_noconntrack

if [ $# != 2 ]; then
        echo "Syntax: /usr/lib64/nagios/plugins/check_noconntrack"
        exit 1
fi

if [ `find /proc/sys -name *conntrack_count | wc -l` -eq "0" ]; then
	echo 'OK: Firewall is NOT running.'
	exit 0
else
	echo 'CRIT: Firewall is running!'
	exit 2
fi

