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
PROGRAM=`/bin/cat /var/nagios/status.dat | /usr/local/program_status.awk`
MAIL="/bin/mail -s" 
SUBJECT="Disabled Nagios notifications *** $DATE" 
RCPT="ccord@machinezone.com"        

if [[ -n $PROGRAM ]] 
then 
#	echo -e $BODY | $MAIL "$SUBJECT" $RCPT 

	/usr/bin/printf  "Notifications disabled on  https://http://monitor.addsrv.com/cgi-bin/nagios3/ $PROGRAM" | $MAIL "$SUBJECT" $RCPT 
else 
	echo "Nothing is disabled..." 
fi
