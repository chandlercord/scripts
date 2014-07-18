#!/bin/sh 
# 
# This program is free software; you can redistribute it and/or 
# modify it under the terms of the GNU General Public License 
# as published by the Free Software Foundation; either Version 2 
# of the License, or (at your option) any later version. 
# 
# This program is distributed in the hope that it will be useful, 
# but WITHOUT ANY WARRANTY; without even the implied warranty of 
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the 
# GNU General Public License for more details. 
# 
# This script was designed to run the two awk scripts host_status.awk and service_status.awk 
# and send an email if anything is returned. 
# 
DATE=`date +%c` 
PROGRAM=`/bin/cat /var/nagios/status.dat | /local/nagios/program_status.awk`
HOST=`/bin/cat /var/nagios/status.dat | /local/nagios/host_status.awk` 
SERVICE=`/bin/cat /var/nagios/status.dat | /local/nagios/service_status.awk` 
MAIL="/bin/mail -s" 
SUBJECT="Daily Disabled Nagios notification $HOSTNAME *** $DATE" 
#RCPT="ops@tango.me" 
RCPT="ccord@tango.me" 

if [[ -n $HOST || -n $SERVICE || -n $PROGRAM ]] 
then 
#	echo -e $BODY | $MAIL "$SUBJECT" $RCPT 

	/usr/bin/printf  "Notifications disabled on https://nagios.us01.tangome.gbl/nagios $PROGRAM\n\n$HOST\n\n$SERVICE" | $MAIL "$SUBJECT" $RCPT 
else 
	echo "Nothing is disabled..." 
fi
