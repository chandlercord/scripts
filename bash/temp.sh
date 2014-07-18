#!/bin/bash

SETTEMP="50"

echo "Please enter the current temperature:"

read TEMP

if [ $TEMP == $SETTEMP ]; then
  echo "Correct, temperature is $TEMP degrees"
elif [ $TEMP -lt $SETTEMP ]; then
  echo "Too cold!"
elif [ $TEMP -gt $SETTEMP ]; then
  echo "Too warm!"
fi
