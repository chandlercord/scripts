#!/bin/sh
sudo /sbin/service rsyslog restart
echo "rsyslog restarted on $HOSTNAME at `date`" >>/tmp/rsyslog_restart.txt
