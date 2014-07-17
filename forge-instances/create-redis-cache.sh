#!/bin/bash
. ../../credentials/ec2.sh
ENVIRONMENTID="$1"
AZID="c"
APPCODE="027"
APPID="rediscache"
REGIONID="usw2"
SIZE="m3.large"
SUBNETIDLIST=$(../bin/ec2-describe-subnets -F "tag:environment=${ENVIRONMENTID}" -F "tag:region=${REGIONID}" -F "tag:app=${APPID}" --hide-tags |awk '{print $2}')
echo "Searching for $APPID security group"
SGROUP=$(../bin/ec2-describe-group -F "tag:app=${APPID}" -F "tag:environment=${ENVIRONMENTID}" -F "tag:region=${REGIONID}"  --hide-tags|grep GROUP | awk '{print $2}')
for SUBNETID in $SUBNETIDLIST; do
	AZID=$(../bin/ec2-describe-subnets $SUBNETID|grep ^TAG |grep 'az' |awk '{print $5}')
	INSTANCENUMLIST=$(../bin/ec2-describe-instances -F "instance-state-name=pending"  -F "instance-state-name=running" -F "tag:environment=${ENVIRONMENTID}" -F "tag:region=${REGIONID}" -F "tag:app=${APPID}" |grep '^TAG'|grep instancenumber| awk '{print $5}')
	#echo "$INSTANCENUMLIST"
	#exit
	for INSTANCENUM in $(seq -w 1 129); do
		if echo $INSTANCENUMLIST |grep $INSTANCENUM &>/dev/null; then
			continue
		else
			break
		fi
	done
	if [ $INSTANCENUM -eq 129 ]; then
		echo "Too many in this region."
		exit 1
	fi
	echo "Trying to create ${REGIONID}-${ENVIRONMENTID}-${APPCODE}-${INSTANCENUM} in subnet ${SUBNETID}"
	NAME="`echo ${REGIONID}-${ENVIRONMENTID}-${APPCODE}-${INSTANCENUM}`"
	TMPFILE=`mktemp`
	cp -rp userdata.sh $TMPFILE
	sed -i "s/NAME=.*/NAME=\"$NAME\"/g" $TMPFILE
	sed -i "s/ENVIRONMENT=.*/ENVIRONMENT=\"$ENVIRONMENTID\"/g" $TMPFILE
	i=""
	for i in node client; do
		yes | knife $i delete $NAME &>/dev/null
	done
	i=""
	INSTANCEID=$(../bin/ec2-run-instances ami-927613a2 --user-data-file $TMPFILE -n 1 -k livemagic_ops -t ${SIZE} --subnet ${SUBNETID} -g ${SGROUP} |grep INSTANCE|awk '{print $2}')
	../bin/ec2-create-tags ${INSTANCEID} --tag Name="${REGIONID}-${ENVIRONMENTID}-${APPCODE}-${INSTANCENUM}" --tag region="${REGIONID}" --tag app="${APPID}" --tag appcode="${APPCODE}" --tag az="${AZID}" --tag environment="${ENVIRONMENTID}" --tag instancenumber="${INSTANCENUM}"
	rm -rf $TMPFILE
done
