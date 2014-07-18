#!/bin/bash

#
# What I inherit:
#   Variables: VPCID TAG REGION AZLIST STARTED VPCSUBNET
#

APPNET="0"
WHICHROUTE="int"
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
	SUBNETID=$(../bin/ec2-describe-subnets -F "tag:region=${REGION}" -F "tag:environment=${TAG}" -F "tag:az=${AZ}" -F "tag:app=${APP}" --hide-tags |awk '{print $2}')
	if [ -z $SUBNETID ];then
		SUBNETID=$(../bin/ec2-create-subnet -c $VPCID -i "$NETWORK" -z $AZONE |awk '{print $2}')
		../bin/ec2-create-tags $SUBNETID --tag environment=${TAG} --tag region=${REGION} --tag az=${AZ} --tag app=${APP}
	fi
	ROUTETBL=$(../bin/ec2-describe-route-tables -F"tag:environment=${TAG}" -F"tag:access=${WHICHROUTE}" -F"tag:region=${REGION}" -F"tag:az=${AZ}" --hide-tags|grep 'rtb-' |awk '{print $2}')
	../bin/ec2-associate-route-table $ROUTETBL -s $SUBNETID
done
