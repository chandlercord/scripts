#!/bin/sh

TMP=/tmp/

cd $TMP
scp us0401ats001:/nas/platform/snmp_scripts.tar.gz .
tar xzvf snmp_scripts.tar.gz
\cp -f tango_validation.pl /root/.
\cp -f filter_contacts.pl /root/.
\cp -f oob_notification.pl /root/.
\cp -f iostat-persist.pl /usr/local/bin/.

echo -e "\ncom2sec mynetwork 127.0.0.1        like2Tang0\nextend tango_validation /usr/bin/perl /root/tango_validation.pl\nextend filter_contacts /usr/bin/perl /root/filter_contacts.pl\nextend oob_notification /usr/bin/perl /root/oob_notification.pl\npass_persist .1.3.6.1.3.1 /usr/bin/perl /usr/local/bin/iostat-persist.pl" >> /etc/snmp/snmpd.conf
echo "* * * * * root cd /tmp && iostat -xkd 30 2 | sed s/,/./g > io.tmp && mv io.tmp iostat.cache" > /etc/cron.d/iostat

service snmpd restart
