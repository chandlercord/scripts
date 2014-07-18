#!/bin/bash

SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

for i in `ls`; do
  #echo "$i"
done

IFS=$SAVEIFS
