#!/bin/bash -x
#
# Nagios script to check website is up and responding in a timely manner

### Environment paths
#NETCAT=`which nc`
#DATE=`which date`
#WGET=`which wget`
#ECHO=`which echo`
#AWK=`which awk`
#CKSUM=`which cksum`
#TR=`which tr`

NETCAT=/usr/bin/nc
DATE=/bin/date
WGET=/usr/bin/wget
ECHO=/bin/echo
AWK=/bin/awk
CKSUM=/usr/bin/cksum
TR=/usr/bin/tr
GREP=/bin/grep
SED=/bin/sed
CURL=/usr/bin/curl

# Temp file
WGETOUT=/tmp/wgetoutput

### Functions
# Check dependencies and paths
checkpaths(){
	for PATH in $NETCAT $DATE $WGET $ECHO $AWK $CKSUM $TR; do 
		if [ ! -f "$PATH" ]; then
			STATUS=UNKNOWN
			OUTMSG="ERROR: $PATH does does not exist"
			output
		fi
	done
}



# Check inputs and formats
checkinputs(){
	if [ ! -n "$WARN" ]; then
		ERROR="Warning not set"
		usage
	fi
        case $WARN in
                *[!0-9]*)
		ERROR="Warning must be in milliseconds"
		usage
	esac
	if [ ! -n "$CRIT" ]; then
		ERROR="Critical not set"
		usage
	fi
        case $CRIT in
                *[!0-9]*)
		ERROR="Critical must be in milliseconds"
		usage
	esac
	if [ "$CRIT" -lt "$WARN" ]; then
		ERROR="Critical must be greater than Warning"
		usage
	fi
	if [ ! -n "$NODE" ]; then
		ERROR="HOST not set"
		usage
	fi
	if [ ! -n "$PORT" ]; then
		ERROR="PORT not set"
		usage
	fi
	if [ ! -n "$SLASH" ]; then
		ERROR="URL not set"
		usage
	fi
URL="${NODE}:${PORT}${SLASH}"
}



# Make temp file unique for URL
mktmpfile(){
	WGETOUTCKSUM=$WGETOUT`$ECHO $URL |$CKSUM |$AWK '{print $1}'`
}

# Print usage statement
usage(){
	$ECHO "UNKNOWN - Error: $ERROR"
	$ECHO "Usage: check_website.sh -w <warning milliseconds> -c <critical milliseconds> -h <host> -p <port> -u <url>"
	exit 3
}

# Check if URL resolves, port is open and webpage contains data
checkopen(){
	# Determine PORT from scheme
	SCHEME=`$ECHO $URL |$AWK -F: '{print $1}'| $TR [:upper:] [:lower:]`
	if [ "$SCHEME" = "https" ]; then
		PORT=443
	fi
	
	# Strip scheme out of URL
	case $URL in
		*://*)
			SHORTURL=`$ECHO $URL |$AWK -F"://" '{print $2}'`;;
		*)
			SHORTURL=$URL;;
	esac
	
	# Strip path out of URL
	case $SHORTURL in
		*/*)
			SHORTURL=`$ECHO $SHORTURL |$AWK -F/ '{print $1}'`;;
	esac
	
	# if no scheme check for ports in SHORTURL or else default to 80
	case $SHORTURL in
		*:*@*:*)
			if [ ! -n "$PORT" ]; then
				PORT=`$ECHO $SHORTURL |$AWK -F: '{print $3}'`
			fi
			SHORTURL=`$ECHO $SHORTURL |$AWK -F@ '{print $2}'`
			SHORTURL=`$ECHO $SHORTURL |$AWK -F: '{print $1}'`;;
		*:*@*)
			if [ ! -n "$PORT" ]; then
				PORT=80
			fi
			SHORTURL=`$ECHO $SHORTURL |$AWK -F@ '{print $2}'`;;
		*:*)
			if [ ! -n "$PORT" ]; then
				PORT=`$ECHO $SHORTURL |$AWK -F: '{print $2}'`
			fi
			SHORTURL=`$ECHO $SHORTURL |$AWK -F: '{print $1}'`;;
		*)
			if [ ! -n "$PORT" ]; then
				PORT=80
			fi;;
	esac
	
	# Check if URL resolves and port is open
	if ! $NETCAT -z $SHORTURL $PORT > /dev/null 2>&1; then
		OUTMSG="URL $SHORTURL can't resolve or port $PORT not open"
		STATUS=CRITICAL
		output
	fi
}

# Check page response time
pageload(){
	STARTTIME=$($DATE +%s%N)
	GOGET=`$WGET -O $WGETOUTCKSUM -o ${WGETOUTCKSUM}.output $URL`
	$GOGET
	ENDTIME=$($DATE +%s%N)
	# Check if page can be loaded and contains data
	if [ ! -s "$WGETOUTCKSUM" ]; then
	        OUTMSG="$URL does not contain any data"
		STATUS=CRITICAL
		output
	fi
	TIMEDIFF=$((($ENDTIME-$STARTTIME)/1000000))
	if [ "$TIMEDIFF" -lt "$WARN" ]; then 
		STATUS=OK
	elif [ "$TIMEDIFF" -ge "$WARN" ] && [ "$TIMEDIFF" -lt "$CRIT" ]; then
		STATUS=WARNING
	elif [ "$TIMEDIFF" -ge "$CRIT" ]; then
		STATUS=CRITICAL
	fi
	OUTMSG="$TIMEDIFF ms"
}


# Output statement and exit
output(){
	RESPCODE=`$GREP HTTP ${WGETOUTCKSUM}.output | $SED 's/.*\.\.\. //g;s/ .*//g'`
	OUTCODE=`$SED 's/.*://g;s/}//g' $WGETOUTCKSUM`
	#Due to a bug in videomail webapp, adding an if to capture a 400 response from the webapp. OPS-1701
	if [ "$OUTCODE" = "400" ]; then
		$ECHO "WARNING - 400 - $OUTMSG - `/bin/cat $WGETOUTCKSUM`|Response="$TIMEDIFF"ms;"$WARN";"$CRIT";0"
		exit 1
	fi
	/bin/cat $WGETOUTCKSUM | $GREP error
	if [ "$?" == "0" ]; then
		$ECHO "CRITICAL - $RESPCODE - $OUTMSG - `/bin/cat $WGETOUTCKSUM`|Response="$TIMEDIFF"ms;"$WARN";"$CRIT";0"
		exit 2
	fi
	$ECHO "$STATUS - $RESPCODE - $OUTMSG - `/bin/cat $WGETOUTCKSUM`|Response="$TIMEDIFF"ms;"$WARN";"$CRIT";0"
	if [ "$RESPCODE" != "200" ]; then
		exit 2
	elif [ "$STATUS" = "OK" ]; then
		exit 0
	elif [ "$STATUS" = "WARNING" ]; then
		exit 1
	elif [ "$STATUS" = "CRITICAL" ]; then
		exit 2
	fi
}

### Main
# Input variables
while getopts w:c:h:p:s: option
	do case "$option" in
		w) WARN=$OPTARG;;
		c) CRIT=$OPTARG;;
		h) NODE=$OPTARG;;
		p) PORT=$OPTARG;;
		s) SLASH=$OPTARG;;
		*) ERROR="Illegal option used"
			usage;;
	esac
done

checkpaths
checkinputs
mktmpfile
checkopen
pageload
output
