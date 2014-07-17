#!/bin/bash


if [ $# -ne 3 ]; then
	echo "\$1 is name, \$2 is IP, \$3 is environment"
	exit
fi

NAME=$1
MYIP=$2
ENVIRONMENT=$3
#Write Dynamic DNS keys


echo 'key "'"$ENVIRONMENT.livemagic.internal."'" {
  algorithm hmac-md5;
  secret "jj7OkqnALQT2+eiLb1Mjm3SzodCafA1SP+ne+pG5wXMt8LzpmVKOzJT9 RqUaP+3xldkwdwa/JUgCqud4ZxAgvg==";
};' >~/dns.key

#Add new DNS information to file
echo -e "server 10.100.100.121 \n
debug yes \n
zone $ENVIRONMENT.livemagic.internal \n" >~/addme.dns

OLDIP=$(dig $NAME.$ENVIRONMENT.livemagic.internal. +short)
if [ ! "${OLDIP}.." = ".." ];then
	echo -e "\n update delete $NAME.$ENVIRONMENT.livemagic.internal 60 A $OLDIP\n\n" >>~/addme.dns
fi


echo -e "
update add $NAME.$ENVIRONMENT.livemagic.internal 60 A $MYIP \n

show \n
send" >> ~/addme.dns


sudo nsupdate -k ~/dns.key -v ~/addme.dns
rm -rf ~/addme.dns ~/dns.key
