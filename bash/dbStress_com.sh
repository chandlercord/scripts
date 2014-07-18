#!/bin/sh

#Remote host variables
DB_LIST=$2
FC_LIST=$3

#Connecion and attempt parameters 
MAX_CONNECTIONS=$4
MAX_ATTEMPTS=$5

#List of ABR's for the test
ABREG_LIST=$1

#Working and test directories
WORK_DIR=/nas/abtesting
TEST_DIR=Test-con$MAX_CONNECTIONS-att$MAX_ATTEMPTS-`date '+%F-%H-%M'`

#How to run the script
if [ ! $# == 5 ]; then
  echo "Usage: sh $0 REG_LIST DB_LIST FC_LIST MAX_CONNECTIONS MAX_ATTEMPTS"
  exit
fi

#Grab number of shards
for i in `cat $DB_LIST`; do 
	SHARDS=`ssh $i "cd /localfio; ls -d data[0-9][0-9] | wc -l"`
	echo "Number of shards $i: $SHARDS"
	FIXSHARDS=`echo $SHARDS - 1 | bc`
	echo "Fixed Shards $i: $FIXSHARDS"
done

mkdir $WORK_DIR/$TEST_DIR
cd $WORK_DIR/$TEST_DIR

for i in `cat $ABREG_LIST`; do
	ssh $i "killall -9 java; sleep 2; \rm -rf /local/tomcat/logs/*"
done

#kill all mysqld processes then unmount /localfio
echo "kill all mysqld processes then unmount /localfio"
for i in `cat $DB_LIST`; do
	ssh $i "killall -9 mysqld_safe; killall -9 mysqld; sleep 5; umount /localfio; mount /localfio"
done

#Check and make sure /localfio remounted
echo "Check and make sure /localfio remounted"
for i in `cat $DB_LIST`; do
	if [ `ssh $i "df | grep -c localfio"` != "1" ] ; then
		ssh $i "mount /localfio"
		if [ `ssh $i "df | grep -c localfio"` != "1" ] ; then
			echo "Failed to remount /localfio"
			exit 2
		fi
	fi
done

for i in `cat $DB_LIST`; do
	if [ `ssh $i "df | grep -c localfio"` != "1" ] ; then
		echo "localfio failed to mount, exiting!"
		exit 2
	fi
done

#Startup n mysqld instances
echo "Startup n mysqld instances"
for a in `cat $DB_LIST`; do
	ssh $a "echo -e '/usr/bin/mysqld_safe --defaults-file=/localfio/data\$1/my.cnf &\necho \"Instance 33\$1 started.\"\nexit 1' > /tmp/mysql_start.sh; chmod +x /tmp/mysql_start.sh"
	for b in `seq -f "%02g" 00 $FIXSHARDS`; do
		ssh $a "/tmp/mysql_start.sh $b" &
		#ssh $a "sh /tmp/mysql_start.sh $b &"
		sleep 1
	done
done

#Ensure they started.
echo "Ensure they started."
for i in `cat $DB_LIST`; do
	INSTANCES=`ssh $i "ps -ef | grep mysqld_safe | grep -v grep | wc -l"`
	echo "Number of running mysql instances: $INSTANCES"
	if [ $INSTANCES != 40 ]; then
		echo "Not all mysqld instances $i started properly, i'll exit, you investigate!"
		exit 1
	else
		echo "It worked"
	fi
done

for i in `cat $ABREG_LIST`; do
	ssh $i "/local/tomcat/bin/catalina.sh start"
done

sleep 300

for i in `cat $ABREG_LIST`; do
	wget $i:8080/
	if [[ $? != 0 ]]; then
		echo "Tomcat not started on $i"
		exit 3
	fi
done

#Grab system configuration information from database
echo "Grab system configuration information from database"
for i in `cat $DB_LIST`; do
	ssh $i "sh /nas/chandler/abwd_spreadsheet.sh" &
	for a in `seq -f "%02g" 00 $FIXSHARDS`; do
		scp $i:/localfio/data${a}/my.cnf my.cnf_$a
	done
done

for i in `cat $ABREG_LIST`; do
	scp /local/tools/scripts/dbstress/acdc_spreadsheet.sh $i:/tmp/.
	ssh $i "sh /tmp/acdc_spreadsheet.sh" &
done

for i in `cat $DB_LIST`; do
	while [[ $(echo `ssh $i "ps -ef | grep spreadsheet | grep -v grep | wc -l"`) != "0" ]]; do
		sleep 1
	done
done

for i in `cat $ABREG_LIST`; do
        while [[ $(echo `ssh $i "ps -ef | grep spreadsheet | grep -v grep | wc -l"`) != "0" ]]; do
                sleep 1
        done
done

#Remove old iostat output and start iostat
echo "Remove old iostat output and start iostat on DB servers"
for i in `cat $DB_LIST`; do
	ssh $i "\rm -rf /tmp/done; \rm -rf /tmp/dstat.$i.csv; dstat -tsmlcgr -d -D dm-0,dm-1,fioa1,sdb1,total --disk-util --disk-tps --output /tmp/dstat.$i.csv &" >>/tmp/junk.$i &
done

#Loop through the ABR's and zero out abreg and localhost_access logs, remove old iostat output and start iostat
echo "Loop through the ABR's and zero out abreg and localhost_access logs, remove old iostat output and start iostat"
for i in `cat $ABREG_LIST`; do 
	ssh $i "\rm -rf /tmp/done; \rm -rf /tmp/dstat.$i.csv; dstat -tsmlcgr -d -D dm-0,dm-1,fioa1,sdb1,total --disk-util --disk-tps --output /tmp/dstat.$i.csv &" >> junk.$i &
done

for i in `cat $FC_LIST`; do
	ssh $i "\rm -rf /tmp/$i.ab-search.out"
	ssh $i "\rm -rf /tmp/dstat.$i.csv; dstat -tsmlcgr -d -D dm-0,dm-1,fioa1,sdb1,total --disk-util --disk-tps --output /tmp/dstat.$i.csv &" >> junk.$i &
done

#Start time, since this is when the test really begins
echo "Start time, since this is when the test really begins"
START_TIME=`date +%s`
STIME=`date`

#Loop through ABR's and start the stress test running against them using the parameters set on the command line
echo "Loop through ABR's and start the stress test running against them using the parameters set on the command line"
	for b in `cat $FC_LIST`; do
		#ssh $b "/local/scripts/ab-search.py --server=$a --users=$MAX_CONNECTIONS --attempts=$MAX_ATTEMPTS >> /tmp/$b.ab-search.out &"
		ssh $b "/nas/chandler/ab-search.py --server=10.50.10.101 --users=$MAX_CONNECTIONS --attempts=$MAX_ATTEMPTS --range=16500000000 >> /tmp/$b.ab-search.out &"
	done

#Loop through through facilitators and wait for stress test to complete
for i in `cat $FC_LIST`; do
	while [[ $(echo `ssh $i "ps -ef | grep ab-search | grep -v grep | wc -l"`) != "0" ]]; do
		sleep 1
	done
done

#touch file to kill while loop that is collection information
for i in `cat $ABREG_LIST`; do
	ssh $i "touch /tmp/done"
done



#Copy AB_REG logs over
for i in `cat $ABREG_LIST`; do
	scp $i:/tmp/dstat.$i.csv .
	scp $i:/local/tomcat/logs/tangogear-abregistrar.log tangogear-abregistrar.log-$i
	scp $i:/local/tomcat/logs/tangogear-abregistrar-error.log tangogear-abregistrar-error.log-$i
	scp $i:/local/tomcat/logs/localhost_access_log.`date '+%F'`.txt localhost_access_log.$i
	scp $i:/var/log/messages messages-$i
	scp $i:/tmp/$i.sheet.csv .
done

#Copy DB logs over
for i in `cat $DB_LIST`; do
	scp $i:/tmp/dstat.$i.csv .
	scp $i:/var/log/messages messages-$DB_HOST
	scp $i:/tmp/$i.sheet.csv .
done

for i in `cat $FC_LIST`; do
	scp $i:/tmp/$i.ab-search.out .
        scp $i:/tmp/dstat.$i.csv .
done

#Dump more test parameters into file
echo -e "Number of threads from each ABR: $MAX_CONNECTIONS\nNumber of attempts: $MAX_ATTEMPTS" >> parameters.txt
echo "ABR's used for test:" >>parameters.txt
cat $ABREG_LIST >>parameters.txt

for i in `cat $FC_LIST`; do
	echo "$(echo $i)," >> loader.$i
	echo "1," >> loader.$i
	echo "$(echo $MAX_CONNECTIONS)," >> loader.$i
	echo "$(echo $MAX_ATTEMPTS)," >> loader.$i
done

#for i in `cat $DB_LIST`; do
#	cat dstat.$i.csv | grep -v idl | awk 'BEGIN {FS=","}
#		min=="" {
#		min=max=$13
#	} {
#		if ($13 > max) {max = $13};
#		if ($13 < min) {min = $13};
#		total += $13
#		count += 1
#	} END {
#		#print "minimum CPU:" min;
#		print max",";
#		print total/count",";
#	}'
#done

#for i in `cat $ABREG_LIST`; do
#        cat dstat.$i.csv | grep -v idl | awk 'BEGIN {FS=","}
#                min=="" {
#                min=max=$13
#        } {
#                if ($13 > max) {max = $13};
#                if ($13 < min) {min = $13};
#                total += $13
#                count += 1
#        } END {
#                #print "minimum CPU:" min;
#                print max",";
#                print total/count",";
#        }'
#done

echo -e "`date`\n" >> spreadsheet.csv
cat loader.us0401afc001 >> spreadsheet.csv
for i in `ls dstat.us0401afc*.csv`; do cat $i | sh /local/tools/scripts/dbstress/dstat_numbers_acdc.sh | awk 'FNR>11' > $i.stats | sleep 1; done; paste dstat.us0401afc*stats | sed -e 's/\t//g' >> spreadsheet.csv
echo -e "\n" >> spreadsheet.csv
paste us0401acdc0* >> spreadsheet.csv
for i in `ls dstat.us0401acdc*.csv`; do cat $i | sh /local/tools/scripts/dbstress/dstat_numbers_acdc.sh | awk 'FNR>11' > $i.stats | sleep 1; done; paste dstat.us0401acdc*stats | sed -e 's/\t//g' >> spreadsheet.csv
for i in `ls tangogear-abregistrar.log-us0401acdc0*`; do grep ++++ $i | sed 's/.*totalCount"://g;s/,"elapsedMin":/ /g;s/,"elapsedMax":/ /g;s/,"elapsed":/ /g;s/}//g' | awk '{ print $1/60" "$2" "$3" "$4}' > $i.tangostats; done
for i in `ls *.tangostats`; do cat $i | sh /local/tools/scripts/dbstress/stats.sh > $i.1; done >> spreadsheet.csv
paste *tangostats.1 >> spreadsheet.csv
echo -e "\n" >> spreadsheet.csv
paste us0401abwd00* >> spreadsheet.csv
echo -e "\n\n" >> spreadsheet.csv
for i in `ls dstat.us0401abwd00*.csv`; do cat $i | sh /local/tools/scripts/dbstress/dstat_numbers_abwd.sh | awk 'FNR>11' > $i.stats | sleep 1; done; paste dstat.us0401abwd00*stats | sed -e 's/\t//g' >> spreadsheet.csv
echo -e "\n\n\n" >> spreadsheet.csv
echo "`hostname -s`:$WORK_DIR/$TEST_DIR" >> spreadsheet.csv
sed -i -e 's/\t//g' spreadsheet.csv

echo -e "Address Book Database Test Results\n\n$TESTDIR" | mutt -a spreadsheet.csv -s "Address Book Database Test Results: Threads $MAX_CONNECTIONS Requests $MAX_ATTEMPTS" ccord@tango.me,nathan@tango.me

#Do some logic on start and end time and add that to the parameter file
END_TIME=`date +%s`
ELAPSED=`expr $END_TIME - $START_TIME`
echo "Test started at $STIME and completed at " `date` " Elapsed run time: " `date -d 00:00:$ELAPSED +%H:%M:%S` >> parameters.txt
echo "Results stored in $WORK_DIR/$TEST_DIR"
