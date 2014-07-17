#!/bin/bash


#
# Variables!
#
# Region is the region we're working in.
#   Yes, I will have to do something to add additional regions, later.
# Valid is the "Valid characters" to use in the VPC region.
# Max tag size is the maximum size of the tag
# Reserved IPs are the 10.x.0.0 subnets we use outside of AWS, that we might connect to aws.
#   This prevents collision.
# Started is used to prevent other scripts from running, if it's not set.
#   This script calls those, so... We set it to 1, so that they will run.
# DNS Servers is a comma separated list of DNS hosts.

REGION=usw2
VALID="a-z0-9"
MAXTAGSIZE=4
RESERVEDIPS="10 15"
STARTED=1
DNSSERVERS="10.100.100.121"

help() {
	echo "This script will fire up a new environment's network, complete with tags."
	echo "Someday it will even do NAT and such but that's not today."
	echo "Usage:"
	echo "  $0 tag size"
	echo "	tag - is for the environment tag. Nuvo staging might be n, nstg, nus, or 14, etc. Keep it short. No special characters at all, and no capitalization."
	echo "	size - matters. This tells us how many avalability zones in our silo to fire up. Accepts  1 or 2"
	exit 0
}

subdomainfail() {
	echo "I Failed to create a Subnet by running $1."
	echo "I am cowardly refusing to continue"
	exit 1
}

if [ "$#" != "2" ] ; then
	help
fi

echo "Loading credentials"
. ../../credentials/ec2.sh

if [ "$2" = "1" ]; then
	AZLIST="c"
elif [ "$2" = "2" ]; then
	AZLIST="a b"
else
	echo "I don't know how to create size $2"
	echo "I only do 1 or 2."
	echo -e "\n\n\n\n"
	help
fi
TAGSIZE="${1//[.]}"
if [[ ${1} =~ [^${VALID}] ]]; then
	echo "ERROR:"
	echo "No spaces, no capitalization, and no special characters in the environment name."
	echo -e "\n\n\n\n"
	help
elif [ "$MAXTAGSIZE" -lt "${#TAGSIZE}" ]; then
	echo "ERROR:"
	echo "Keep it short, please"
	echo -e "\n\n\n\n"
	help
else
	TAG=$1
fi

echo "Trying to find the DHCP Options"
DHCPID=$(../bin/ec2-describe-dhcp-options -F "tag:environment=${TAG}" -F "tag:region=${REGION}" --hide-tags |awk '{print $3}')
if [ -z "$DHCPID" ]; then
	echo "... Not found. Trying to build the DHCP Options"
	DHCPID=$(../bin/ec2-create-dhcp-options domain-name-servers="${DNSSERVERS}" domain-name=${TAG}.livemagic.internal |head -1|awk '{print $2}')
	../bin/ec2-create-tags $DHCPID --tag environment=${TAG} --tag region=${REGION}
fi
echo "DHCP Stuff Done."


# Does this VPC exist already?
echo "Attempting to find VPC"
VPCID="$(../bin/ec2-describe-vpcs -F"tag:environment=${TAG}" --hide-tags |awk '{print $3}')"
if [ -z "$VPCID" ]; then
	echo "VPC Not found. Constructing"
	echo "Finding unused subnet space"
	VPCRANGEUSED="$RESERVED_IP $(../bin/ec2-describe-vpcs --hide-tags |awk '{print $4}'|sed 's/^10\.\([0-9]*\)\..*/\1/')"
	for VPC in $VPCRANGEUSED; do
		VPCRANGEPADDED="$(printf "%0*d\n" 3 ${VPC} 2>&1) $VPCRANGEPADDED"
	done
	VPC=""
	for VPCSUBNET in $(seq -w 0 255) ; do
		if echo $VPCRANGEPADDED |grep $VPCSUBNET &>/dev/null ; then
			continue
		else
			echo "Found unused space in 10.$VPCSUBNET"
			break
		fi
	done
	echo "Building VPC"
	VPCID=$(../bin/ec2-create-vpc "10.$(echo $VPCSUBNET|bc).0.0/16" |awk '{print $2}')
	echo "Done building"
else
	echo "Found VPC"
	VPCSUBNET=$(../bin/ec2-describe-vpcs -F"tag:environment=${TAG}" --hide-tags |awk '{print $4}'|sed 's/^10\.\([0-9]*\)\..*/\1/')
	echo "For now, we exit. We might do more later"
	exit 1
fi
echo "Tagging our VPC"
../bin/ec2-create-tags $VPCID --tag environment=${TAG} --tag region=${REGION}
echo "Adding DHCP Options"
../bin/ec2-associate-dhcp-options $DHCPID -c $VPCID

#
# Routes
#

echo "Attempting to find Internet gateways"
IGWID=$(../bin/ec2-describe-internet-gateways -F "tag:environment=${TAG}" -F "tag:region=${REGION}" --hide-tags|grep igw-|awk '{print $2}')
if [ -z "$IGWID" ]; then
	echo "Not found. Building Internet Gateway"
	IGWID=$(../bin/ec2-create-internet-gateway |grep igw-|awk '{print $2}')
	echo "Tagging our Gateway"
	../bin/ec2-create-tags $IGWID --tag environment=${TAG} --tag region=${REGION}
fi
echo "Attatching our Internet Gateway"
../bin/ec2-attach-internet-gateway $IGWID -c $VPCID

echo "Routing steps for Availability zones $AZLIST"
for AZ in $AZLIST; do 
	echo "Finding routes for Availability zone $AZ"
	INTROUTE=$(../bin/ec2-describe-route-tables -F"tag:environment=${TAG}" -F"tag:access=int" -F"tag:region=${REGION}" -F"tag:az=${AZ}" --hide-tags|grep 'rtb-' |awk '{print $2}')
	EXTROUTE=$(../bin/ec2-describe-route-tables -F"tag:environment=${TAG}" -F"tag:access=ext" -F"tag:region=${REGION}" -F"tag:az=${AZ}" --hide-tags|grep 'rtb-' |awk '{print $2}')
	if [ -z "$INTROUTE" ] ;then
		echo "Internal route not found for AZ $AZ"
		INTROUTE=$(../bin/ec2-create-route-table $VPCID | grep 'rtb-' |awk '{print $2}')
		../bin/ec2-create-tags $INTROUTE --tag environment=${TAG} --tag region=${REGION} --tag az=${AZ} --tag access=int
		echo "Internal route built for AZ $AZ"
	fi
	if [ -z "$EXTROUTE" ] ;then
		echo "External route not found for AZ $AZ"
		EXTROUTE=$(../bin/ec2-create-route-table $VPCID | grep 'rtb-' |awk '{print $2}')
		../bin/ec2-create-tags $EXTROUTE --tag environment=${TAG} --tag region=${REGION} --tag az=${AZ} --tag access=ext
		echo "EXternal route built for AZ $AZ"
	fi
	echo "Adding default route for External Route in AZ $AZ"
	../bin/ec2-create-route $EXTROUTE -r "0.0.0.0/0" -g $IGWID 
done


#
# The rest of the routes will be built by the NAT device creation script.
#

export VPCID TAG REGION AZLIST STARTED VPCSUBNET



echo "Subdomains starting now"
for SUBDOMAIN in subdomainscripts/*domain.sh ; do
	./${SUBDOMAIN} || subdomainfail $SUBDOMAIN
done
