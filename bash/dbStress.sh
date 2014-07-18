#!/bin/sh

#Remote host variables
DB_HOST=$2
FC_LIST=$3

#Connecion and attempt parameters 
MAX_CONNECTIONS=$4
MAX_ATTEMPTS=$5

#List of ABR's for the test
ABREG_LIST=$1

#Working and test directories
WORK_DIR=/tmp
TEST_DIR=Test-con$MAX_CONNECTIONS-att$MAX_ATTEMPTS-`date '+%F-%H-%M'`

#Grab number of shards
SHARDS=`ssh $DB_HOST "ls /localfio | wc -l"`
echo "Number of shards: $SHARDS"
FIXSHARDS=`echo $SHARDS - 1 | bc`
echo "Fixed Shards: $FIXSHARDS"

#How to run the script
if [ ! $# == 5 ]; then
  echo "Usage: sh $0 REG_LIST DB_HOST FC_LIST MAX_CONNECTIONS MAX_ATTEMPTS"
  exit
fi

mkdir $WORK_DIR/$TEST_DIR
cd $WORK_DIR/$TEST_DIR

#kill all mysqld processes then unmount /localfio
echo "kill all mysqld processes then unmount /localfio"
ssh $DB_HOST "killall -9 mysqld_safe; killall -9 mysqld; sleep 5; umount /localfio; mount /localfio"

#Check and make sure /localfio remounted
echo "Check and make sure /localfio remounted"
if [ `ssh $DB_HOST "df | grep -c localfio"` != "1" ] ; then
	ssh $DB_HOST "mount /localfio"
	if [ `ssh us0101abrd002 "df | grep -c localfio"` != "1" ] ; then
		echo "Failed to remount /localfio"
		exit 2
	fi
fi

if [ `ssh $DB_HOST "df | grep -c localfio"` != "1" ] ; then
	echo "localfio failed to mount, exiting!"
	exit 2
fi

#Startup n mysqld instances
echo "Startup n mysqld instances"
#ssh $DB_HOST "for i in `seq -f "%02g" 00 63`; do echo $i; done"
ssh $DB_HOST "echo -e '/usr/bin/mysqld_safe --defaults-file=/localfio/data\$1/my.cnf &\necho \"Instance 33\$1 started.\"\nexit 1' > /tmp/mysql_start.sh; chmod +x /tmp/mysql_start.sh"
for i in `seq -f "%02g" 00 $FIXSHARDS`; do
	ssh $DB_HOST "/tmp/mysql_start.sh $i" &
	#ssh $DB_HOST "sh /tmp/mysql_start.sh $i &"
	sleep 1
done

#Ensure they started.
echo "Ensure they started."
INSTANCES=`ssh $DB_HOST "ps -ef | grep mysqld_safe | grep -v grep | wc -l"`
echo "Number of running mysql instances: $INSTANCES"
if [ 64 != 64 ]; then
	echo "Not all mysqld instances started properly, i'll exit, you investigate!"
	exit 1
else
	echo "It worked"
fi

#Grab system configuration information from database
echo "Grab system configuration information from database"
#ssh $DB_HOST 'hostname; echo "Number of shards: `ls /localfio | wc -l`"; for i in `seq -f "%02g" 00 $(echo $(ls /localfio/ | wc -l) - 1 | bc)`; do echo "Shard 33$i: `mysql -uabWrite -pstealurContacts -h $(hostname) -P 33$i -e "select count(*) from addressbook.contact;"| grep -v '-' | grep -v count`"; done; df -h' >> parameters.txt
#for i in `seq -f "%02g" 00 $(echo $(grep shards parameters.txt | awk '{ print $4 }') - 1 | bc)`; do scp $DB_HOST:/localfio/data$i/my.cnf my.cnf_$i; done

#Remove old iostat output and start iostat
echo "Remove old iostat output and start iostat"
ssh $DB_HOST "\rm -rf /tmp/done; \rm -rf /tmp/iostat; while [ ! -f /tmp/done ]; do date '+%F-%H-%M-%S'; iostat -xm; sleep 1; done >> /tmp/iostat &"

#Loop through the ABR's and zero out abreg and localhost_access logs, remove old iostat output and start iostat
echo "Loop through the ABR's and zero out abreg and localhost_access logs, remove old iostat output and start iostat"
for i in `cat $ABREG_LIST`; do 
	ssh $i '\cp /dev/null /local/tomcat/logs/tangogear-abregistrar.log; \cp /dev/null /local/tomcat/logs/localhost_access_log.`date '+%F'`.log; \rm -rf /tmp/done; \rm -rf /tmp/iostat; while [ ! -f /tmp/done ]; do date '+%F-%H-%M-%S'; iostat -xm; sleep 1; done >> /tmp/iostat' \&
done

#Start time, since this is when the test really begins
echo "Start time, since this is when the test really begins"
START_TIME=`date +%s`
STIME=`date`

#Loop through ABR's and start the stress test running against them using the parameters set on the command line
echo "Loop through ABR's and start the stress test running against them using the parameters set on the command line"
for a in `cat $ABREG_LIST`; do 
	for b in `cat $FC_LIST`; do
		ssh $b "/local/scripts/ab-search.py --server=$a --users=$MAX_CONNECTIONS --attempts=$MAX_ATTEMPTS" &
	done
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

#touch file to kill while loop that is collection information
ssh $DB_HOST "touch /tmp/done"

#Copy AB_REG logs over
for i in `cat $ABREG_LIST`; do
	scp $i:/tmp/iostat iostat-$i
	scp $i:/local/tomcat/logs/tangogear-abregistrar.log tangogear-abregistrar.log-$i
	scp $i:/local/tomcat/logs/tangogear-abregistrar-error.log tangogear-abregistrar-error.log-$i
	scp $i:/var/log/messages messages-$i
done

#Copy DB logs over
scp $DB_HOST:/tmp/iostat iostat-$DB_HOST
scp $DB_HOST:/var/log/messages messages-$DB_HOST

#Dump more test parameters into file
echo -e "Number of threads from each ABR: $MAX_CONNECTIONS\nNumber of attempts: $MAX_ATTEMPTS" >> parameters.txt
echo "ABR's used for test:" >>parameters.txt
cat $ABREG_LIST >>parameters.txt

#Do some logic on start and end time and add that to the parameter file
END_TIME=`date +%s`
ELAPSED=`expr $END_TIME - $START_TIME`
echo "Test started at $STIME and completed at " `date` " Elapsed run time: " `date -d 00:00:$ELAPSED +%H:%M:%S` >> $WORK_DIR/$TEST_DIR/parameters.txt
