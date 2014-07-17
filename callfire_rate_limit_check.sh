#!/bin/bash

##############################################
### Written by Chandler Cord ccord@8x8.com ###
##############################################

#Counts the number of rate limit errors in the last 2.5 million lines of the current log. Roughly the last 10 minutes during peak time.
COUNT=$(tail -n 2500000 /p8senez/logs/`hostname`.p8t.us-all-`date '+%F-%H'`.log | grep SEVERE | grep rate | wc -l)

#Dumps logs into file /tmp/cf_exceptions.{yyyy-mm-dd-hh-mm}
GRABEXCEPTIONS=$(tail -n 10000000 /p8senez/logs/`hostname`.p8t.us-all-`date '+%F-%H'`.log | grep SEVERE | grep rate > /tmp/cf_exceptions.`date '+%F-%H-%M'`)

#Location of dump file
EXCEPTIONFILE=/tmp/cf_exceptions.`date '+%F-%H-%M'`

#While loop that checks if there are more then 10 errors in the log, if so, emails out to noc
while [ 0 ]; do
	if [ $COUNT -gt "10" ]; then
		$GRABEXCEPTIONS
		echo -e "Greetings\n\n$COUNT rate limit errors detected on `hostname`. Please see errors below.\n\nThank you,\nYour frendly automated log checker\n\n------------------------------------\n `cat $EXCEPTIONFILE`" | mail -s "Callfire rate limit errors detected on `hostname`" ccord@8x8.com
	fi
	sleep 300
done

