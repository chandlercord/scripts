#!/bin/bash

######################################
##                                  ##
## Written by Chandler Cord         ##
## 09/17/2012 ccord@machinezone.com ##
##                                  ##
######################################

DC1=addsrv
DC2=com
TMPDIR="/tmp"
FIRST=""
LAST=""
USERNAME=""
PASSWORD=""
USAGE="This is a script to add LDAP users and generate a random password if needed.\nThe following options are available.\n\n-F: First name\n-L: Last name.\n-U: Username\n-P: Password\n\n-F and -L are required arguements, -U and -P are optional\n\nExample: $0 -F John -L Smith -u jsmith"

while getopts "F:L:U:P:h" ARG; do
	case $ARG in
		F) FIRST=$OPTARG;;
		L) LAST=$OPTARG;;
		U) USERNAME=$OPTARG;;
		P) PASSWORD=$OPTARG;;
		h) echo -e $USAGE; exit;;
		?) echo -e $USAGE; exit;;
	esac
done

if [ -z "$FIRST" -a -z "$LAST" ]; then 
	echo -e "First and Last name are empty, please try again\n\n$USAGE"; exit
fi

if [ -z "$FIRST" ]; then
	echo -e "First name is empty, please try again\n\n$USAGE"; exit
fi

if [ -z "$LAST" ]; then
	echo -e "Last name is empty, please try again\n\n$USAGE"; exit
fi

USERNAME=`echo "$(echo $FIRST | cut -c1 | tr '[:upper:]' '[:lower:]')$(echo $LAST | tr '[:upper:]' '[:lower:]')"`
TMPFILE=`mktemp ${TMPDIR}/${USERNAME}.ldif.XXXXXXXX`

if [ -z "$PASSWORD" ]; then 
	#PASSWORD=`< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c ${1:-10};echo;`
	PASSWORD=`date +%s | sha256sum | base64 | head -c 10`
fi

LAST_UID=`ldapsearch -x -h localhost -b "dc=addsrv,dc=com" "(objectClass=*)" | grep uidNumber | tail -1 | awk '{ print $2 }'`
LAST_GID=`ldapsearch -x -h localhost -b "dc=addsrv,dc=com" "(objectClass=*)" | grep gidNumber | tail -1 | awk '{ print $2 }'`
NEWUID=`echo "${LAST_UID} + 1" | bc`
NEWGID=`echo "${LAST_GID} + 1" | bc`
HASHED_PASSWORD=`slappasswd -s $PASSWORD`

cat > $TMPFILE <<EOF
dn: cn=$FIRST $LAST,ou=people,dc=$DC1,dc=$DC2
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
sn: $LAST
cn: $FIRST $LAST
gidNumber: $NEWGID
homeDirectory: /home/$USERNAME
uid: $USERNAME
uidNumber: $NEWUID
displayName: $FIRST $LAST
givenName: $FIRST
loginShell: /bin/bash
mail: $USERNAME@machinezone.com
userPassword: $HASHED_PASSWORD
EOF

#echo -e "New user created!\nUsername: $USERNAME\nFirst name: $FIRST\nLast name: $LAST\nUID: $NEWUID\nPASSWORD: $PASSWORD - Please change immediately\n"
cat $TMPFILE; echo "Password: $PASSWORD"

while true; do
    read -p "Do you wish to create the above user? (y/n) " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) echo "Giving up!"; exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

echo "Adding $USERNAME to LDAP"
ldapadd -x -D cn=admin,dc=addsrv,dc=com -W -f $TMPFILE

rm $TMPFILE