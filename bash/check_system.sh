#!/bin/bash

#define syslog date format
log_date=$(date '+%b %Y %d %H:%M:%S')

#From and to email addresses
EMAIL_ADDRESS="chandlercord@gmail.com"
FROM_EMAIL="chandlercord@gmail.com"

check_disk(){
#Disk critical percentage threshold
DISK_CRIT=90

df -H | grep -vE '^Filesystem|tmpfs|cdrom' | awk '{ print $5 " " $1 " " $6 }' | while read output; do
  usep=$(echo $output | awk '{ print $1}' | cut -d'%' -f1  )
  mount=$(echo $output | awk '{ print $2 }' )
  partition=$(echo $output | awk '{ print $3 }' )

  if [ ${usep} -ge ${DISK_CRIT} ]; then
    echo "${log_date}: Disk space critical - ${partition} ($usep%)"
    echo "${log_date}: Disk space critical - ${partition} ($usep%)" | mail -s "$HOSTNAME: Disk space critical" -a "From: ${FROM_EMAIL}" ${EMAIL_ADDRESS}
    exit 1
  else
    echo "${log_date}: Disk space is OK - ${partition} ($usep%)"
  fi
done
}

check_mem(){
MEM_CRIT=95
MEM_TOTAL=`free | fgrep "Mem:" | awk '{print $2}'`;
MEM_USED=`free | fgrep "/+ buffers/cache" | awk '{print $3}'`;

PERCENTAGE=$(($MEM_USED*100/$MEM_TOTAL))

if [ ${PERCENTAGE} -ge ${MEM_CRIT} ]; then
  echo "${log_date}: Memory usage critical - ${PERCENTAGE}" | mail -s "$HOSTNAME: Memory usage critical" -a "From: ${FROM_EMAIL}" ${EMAIL_ADDRESS}
  exit 2
else
  echo "${log_date}: Memory usage OK - ${PERCENTAGE}"
fi
}

check_cpu(){
  CPU_CRIT=95
  CPU_USAGE=`echo $[100-$(vmstat|tail -1|awk '{print $15}')]`
  if [ ${CPU_USAGE} -ge ${CPU_CRIT} ]; then
    echo "${log_date}: CPU usage critical - ${CPU_USAGE} percent" | mail -s "$HOSTNAME: CPU usage critical" -a "From: ${FROM_EMAIL}" ${EMAIL_ADDRESS}
    exit 3
  else
    echo "${log_date}: CPU usage OK - ${CPU_USAGE} percent"
  fi
}

check_disk || if [ $? == "1" ]; then echo "Disk critical"; exit 1; fi
check_mem || if [ $? == "2" ]; then echo "Memory critical"; exit 2; fi
check_cpu || if [ $? == "3" ]; then echo "CPU critical"; exit 3; fi
