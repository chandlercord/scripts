#!/bin/bash

echo -n "What Datacenter is this for? (i.e. 0401, 0101)\n"
read LOCATION
#echo "Location: $LOCATION"

echo -n "What class of server? (i.e. ats, abwd)\n"
read CLASS
#echo "Class: $CLASS"

echo -n "How many servers are you adding?\n"
read NUMBER
echo "us'$LOCATION''$CLASS'0'$NUMBER'"
