#!/bin/bash
#. ../../credentials/ec2.sh
APPCODE="002"
APPID="nat"
SIZE="t1.micro"
SUBNETIDLIST=$(../bin/ec2-describe-subnets -F "tag:environment=${TAG}" -F "tag:region=${REGION}" -F "tag:app=${APPID}" -F "tag:az=${AZ}" --hide-tags |awk '{print $2}')
for SUBNETID in $SUBNETIDLIST; do
	INSTANCENUMLIST=$(../bin/ec2-describe-instances -F "instance-state-name=pending"  -F "instance-state-name=running" -F "tag:environment=${TAG}" -F "tag:region=${REGION}" -F "tag:app=${APPID}" |grep '^TAG'|grep instancenumber| awk '{print $5}')
	#echo "$INSTANCENUMLIST"
	#exit
	for INSTANCENUM in 001 002 003; do
		if echo $INSTANCENUMLIST |grep $INSTANCENUM &>/dev/null; then
			continue
		else
			break
		fi
	done
	if [ $INSTANCENUM = "003" ];then
		echo "already found two nats"
		exit 1
	fi
	echo "Trying to create ${REGION}-${TAG}-${APPCODE}-${INSTANCENUM} in subnet ${SUBNETID}"
	NAME="`echo ${REGION}-${TAG}-${APPCODE}-${INSTANCENUM}`"
	TMPFILE=`mktemp`
	cp -rp subdomainscripts/nat-userdata.sh $TMPFILE
	sed -i "s/^NAME=.*/NAME=\"$NAME\"/g" $TMPFILE
	sed -i "s/^DNSSERVER=.*/DNSSERVER=10.100.100.121/g" $TMPFILE
	sed -i "s/^TAG=.*/TAG=\"$TAG\"/g" $TMPFILE
	echo "Chef cleanup"
	i=""
	for i in node client; do
		yes | knife $i delete $NAME &>/dev/null
	done
	i=""
	echo "Creating NAT instance in subnet $SUBNETID and availability zone $AZ"
	INSTANCEID=$(../bin/ec2-run-instances ami-f032acc0 --user-data-file $TMPFILE -g $SGROUP -n 1 -k livemagic_ops -t ${SIZE} --subnet ${SUBNETID} --associate-public-ip-address TRUE|grep INSTANCE|awk '{print $2}')
	echo "Tagging $INSTANCEID"
	../bin/ec2-create-tags ${INSTANCEID} --tag Name="${REGION}-${TAG}-${APPCODE}-${INSTANCENUM}" --tag region="${REGION}" --tag app="${APPID}" --tag appcode="${APPCODE}" --tag az="${AZ}" --tag environment="${TAG}" --tag instancenumber="${INSTANCENUM}"
	#rm -rf $TMPFILE
	echo "Making the Nat, Natlike"
	../bin/ec2-modify-instance-attribute --source-dest-check false ${INSTANCEID}
	echo "Searching for Routes"
	INTROUTE=$(../bin/ec2-describe-route-tables -F"tag:environment=${TAG}" -F"tag:access=int" -F"tag:region=${REGION}" -F"tag:az=${AZ}" --hide-tags|grep 'rtb-' |awk '{print $2}')
	EXTROUTE=$(../bin/ec2-describe-route-tables -F"tag:environment=${TAG}" -F"tag:access=ext" -F"tag:region=${REGION}" -F"tag:az=${AZ}" --hide-tags|grep 'rtb-' |awk '{print $2}')
	echo "Entering loop to wait for instance to come up."
	MYSTATE="waiting"
	while [ ! "$MYSTATE" = "running" ] ; do
		sleep 1
		echo "Waiting on Nat instance $INSTANCEID. It's state is $MYSTATE"
		MYSTATE=$(../bin/ec2-describe-instance-status $INSTANCEID -A |head -1|awk '{print $4}')
	done
	echo "Fetching my External IP Address"
	EXTIP=$(../bin/ec2-describe-instances $INSTANCEID |grep NICASSOC|awk '{print $2}')
	echo "Adding my External IP address to core's allowed lists"
	CORESG=$(../bin/ec2-describe-group -F "tag:app=${APP}" -F "tag:environment=c" -F "tag:region=${REGION}"  --hide-tags|grep GROUP | awk '{print $2}')
	../bin/ec2-authorize $CORESG -P all -s 10.${VPCSUBNET}.0.0/16
	../bin/ec2-authorize $CORESG -P all -s $EXTIP/32
	echo "Completing NAT instance $INSTANCEID and assigning routes."
	../bin/ec2-create-route $EXTROUTE -r "10.100.100.0/24" -i $INSTANCEID
	../bin/ec2-create-route $EXTROUTE -r "10.15.0.0/16" -i $INSTANCEID
	../bin/ec2-create-route $INTROUTE -r "10.100.100.0/24" -i $INSTANCEID
	../bin/ec2-create-route $INTROUTE -r "10.15.0.0/16" -i $INSTANCEID
	../bin/ec2-create-route $INTROUTE -r "0.0.0.0/0" -i $INSTANCEID
done
