#!/bin/bash -v

NAME=blah
MYIP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4/)

ENVIRONMENT=blah
MANAGEMENT_CODE=001
NAT_CODE=002
JENKINS_CODE=004
MONITORING_CODE=005
GRAPHITE_CODE=006
COREDB_CODE=007
BASTION_CODE=007
CODEX_CODE=011
STREAMING_SERVER_CODE=012
AFP_CODE=013
VFP_CODE=014
REEF_CODE=015
CLIP_EXTRACTOR_CODE=016
ORCA_CODE=021
ORCADB_CODE=022
ORCACACHE_CODE=023
SOLR_CODE=024
ORCASTORAGE_CODE=025
ORCAUVC_CODE=026

sudo apt-get update

#Update hostname
sudo hostname $NAME
sudo echo $NAME > /tmp/hostname
sudo cp -rp /tmp/hostname /etc/hostname

#Install s3cmd and chef-client
sudo apt-get install -y s3cmd
sudo curl -L https://www.opscode.com/chef/install.sh | sudo bash
sudo mkdir -p /etc/chef/

# write first-boot.json
if [ "${ENVIRONMENT}" = "ni" ]; then
  echo '{"run_list": [ "role[base]" ]}' > /etc/chef/first-boot.json
else
  case $NAME in
    ????-*-${CODEX_CODE}-???)
      echo '{"run_list": [ "role[base]", "role[codex]" ]}' > /etc/chef/first-boot.json
    ;;
    ????-*-${STREAMING_SERVER_CODE}-???)
      echo '{"run_list": [ "role[base]", "role[streaming-server]" ]}' > /etc/chef/first-boot.json
    ;;
    ????-*-${ORCA_CODE}-???)
      echo '{"run_list": [ "role[base]", "role[orca]" ]}' > /etc/chef/first-boot.json
    ;;
    ????-*-${ORCADB_CODE}-???)
      echo '{"run_list": [ "role[base]", "role[orcadb]" ]}' > /etc/chef/first-boot.json
    ;;
    ????-*-${SOLR_CODE}-???)
      echo '{"run_list": [ "role[base]", "role[solr]" ]}' > /etc/chef/first-boot.json
    ;;
    ????-*-${ORCASTORAGE_CODE}-???)
      echo '{"run_list": [ "role[base]", "role[orcastorage]" ]}' > /etc/chef/first-boot.json
    ;;
    ????-*-${JENKINS_CODE}-???)
      echo '{"run_list": [ "role[base]", "role[jenkins]" ]}' > /etc/chef/first-boot.json
    ;;
    ????-*-${MONITORING_CODE}-???)
      echo '{"run_list": [ "role[base]", "role[monitoring]" ]}' > /etc/chef/first-boot.json
    ;;
    ????-*-${COREDB_CODE}-???)
      echo '{"run_list": [ "role[base]", "role[coredb]" ]}' > /etc/chef/first-boot.json
    ;;
    ????-*-${GRAPHITE_CODE}-???)
      echo '{"run_list": [ "role[base]", "role[graphite]" ]}' > /etc/chef/first-boot.json
    ;;
    ????-*-${BASTION_CODE}-???)
      echo '{"run_list": [ "role[base]", "role[bastion]" ]}' > /etc/chef/first-boot.json
    ;;
    *)
      echo '{"run_list": [ "role[base]" ]}' > /etc/chef/first-boot.json
    ;;
  esac
fi

# write .s3cfg
(
sudo cat << 'EOP'
[default]
access_key = AKIAIKG6Y6EZM5Z27AWA
secret_key = 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
use_https = True
EOP
) > /home/ubuntu/.s3cfg

# get chef validation key from S3
sudo s3cmd -c /home/ubuntu/.s3cfg get s3://lmstaging-systems/validation-core.pem 
sudo mv validation-core.pem /etc/chef/validation.pem 

# write client.rb
(
sudo cat << 'EOP'
log_level :info
log_location STDOUT
chef_server_url 'https://chef.c.livemagic.internal'
validation_client_name 'chef-validator'
EOP
) > /etc/chef/client.rb

#Write Dynamic DNS keys

echo 'key "'"$ENVIRONMENT.livemagic.internal."'" {
  algorithm hmac-md5;
  secret "jj7OkqnALQT2+eiLb1Mjm3SzodCafA1SP+ne+pG5wXMt8LzpmVKOzJT9 RqUaP+3xldkwdwa/JUgCqud4ZxAgvg==";
};' >/root/dns.key

#Add new DNS information to file
echo -e "server 10.100.100.121 \n
debug yes \n
zone $ENVIRONMENT.livemagic.internal \n" >/root/addme.dns

OLDIP=$(dig $NAME.$ENVIRONMENT.livemagic.internal. +short)
if [ ! "${OLDIP}.." = ".." ];then
	echo -e "\n update delete $NAME.$ENVIRONMENT.livemagic.internal 60 A $OLDIP\n\n" >>/root/addme.dns
fi


echo -e "
update add $NAME.$ENVIRONMENT.livemagic.internal 60 A $MYIP \n

show \n
send" >> /root/addme.dns

echo "node_name \"$NAME\"" >> /etc/chef/client.rb
# Bootstrap chef

sudo nsupdate -k /root/dns.key -v /root/addme.dns
#rm -rf  /root/dns.key /root/addme.dns /home/ubuntu/.s3cfg

sudo nohup /usr/bin/chef-client -j /etc/chef/first-boot.json &>/root/chef-first-run.log &
