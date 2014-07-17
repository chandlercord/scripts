#!/bin/bash

#
# What I do:
#   I make the NAT/VPN machine subnet and route.
# What I inherit:
#   Variables: VPCID TAG REGION AZLIST STARTED VPCSUBNET
#
echo "Creating Nat"
APPNET="100"
WHICHROUTE="ext"
APP="nat"
if [ -z $STARTED ]; then
	echo "Please don't run me directly."
	exit 1
fi


for AZ in $AZLIST; do
	case $AZ in
		a)
			NETWORK=10.${VPCSUBNET}.${APPNET}.0/25
			AZONE=us-west-2${AZ}
		;;
		b)
			NETWORK=10.${VPCSUBNET}.${APPNET}.128/25
			AZONE=us-west-2${AZ}
		;;
		c)
			NETWORK=10.${VPCSUBNET}.${APPNET}.0/24
			AZONE=us-west-2${AZ}
		;;
		*)
			echo "I do not know how to proceed with availability zone $AZ"
			exit 1
		;;
	esac
	echo "Finding Subnet"
	SUBNETID=$(../bin/ec2-describe-subnets -F "tag:region=${REGION}" -F "tag:environment=${TAG}" -F "tag:az=${AZ}" -F "tag:app=${APP}" --hide-tags |awk '{print $2}')
	if [ -z "$SUBNETID" ];then
		echo "Subnet not found. Constructing"
		SUBNETID=$(../bin/ec2-create-subnet -c $VPCID -i "$NETWORK" -z $AZONE |awk '{print $2}')
		../bin/ec2-create-tags $SUBNETID --tag environment=${TAG} --tag region=${REGION} --tag az=${AZ} --tag app=${APP}
	fi
	echo "Finding route table and associating it."
	ROUTETBL=$(../bin/ec2-describe-route-tables -F"tag:environment=${TAG}" -F"tag:access=${WHICHROUTE}" -F"tag:region=${REGION}" -F"tag:az=${AZ}" --hide-tags|grep 'rtb-' |awk '{print $2}')
	../bin/ec2-associate-route-table $ROUTETBL -s $SUBNETID
done
echo "Searching for nat security group"
SGROUP=$(../bin/ec2-describe-group -F "tag:app=${APP}" -F "tag:environment=${TAG}" -F "tag:region=${REGION}"  --hide-tags|grep GROUP | awk '{print $2}')
if [ -z "$SGROUP" ]; then
	echo "Nat Security group not found. Constructing"
        SGROUP=$(../bin/ec2-create-group NATSG -d NAT -c $VPCID |awk '{print $2}')
        ../bin/ec2-create-tags $SGROUP  --tag "app=${APP}" --tag "environment=${TAG}" --tag "region=${REGION}"
	../bin/ec2-authorize $SGROUP -P all -s 10.100.100.0/24
	../bin/ec2-authorize $SGROUP -P all -s 10.15.0.0/16
	../bin/ec2-authorize $SGROUP -P all -s 54.218.19.145/32
	../bin/ec2-authorize $SGROUP -P all -s 65.17.247.242/32
	../bin/ec2-authorize $SGROUP -P all -s 65.17.247.243/32
	../bin/ec2-authorize $SGROUP -P all -s 10.${VPCSUBNET}.0.0/16
fi

echo "Trying to build nat instances"
for AZ in $AZLIST; do
	export SGROUP AZ
	( ./subdomainscripts/create-nat-instance.sh &)
	echo "Sleeping between Nat Construcions"
	sleep 10
done
echo "Nat complete"

