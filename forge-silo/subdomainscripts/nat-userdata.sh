#!/bin/bash -v

NAME=XXXXX
DNSSERVER=YYYYY
TAG=ZZZZZ
MYIP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4/)

NAT_CODE=002
#We don't have functioning DNS yet.
echo "prepend domain-name-servers 8.8.8.8;">>/etc/dhcp/dhclient.conf
/sbin/dhclient -r
/sbin/dhclient
/etc/init.d/network restart

#Update hostname
sudo hostname $NAME
sudo echo $NAME > /tmp/hostname
sudo cp -rp /tmp/hostname /etc/hostname

#Install s3cmd and chef-client
sudo wget http://s3tools.org/repo/RHEL_6/s3tools.repo -O /etc/yum.repos.d/s3tools.repo
sudo yum -y install s3cmd
sudo yum -y install openswan
#sudo curl -L https://www.opscode.com/chef/install.sh | sudo bash
sudo mkdir -p /etc/chef/

#Set up tunnels:
sudo echo "include /etc/ipsec.d/*.conf">>/etc/ipsec.conf
mkdir -p  /etc/ipsec.d/
echo "conn $NAME-to-core
  type=tunnel
	authby=secret
	left=%defaultroute
	leftid=XXXXXXXXXXXXX
	leftnexthop=%defaultroute
	leftsubnet=XXXXXXXXXXXXXX
	#leftsubnets={XXXXXXXXXXXXXXX,XXXXXXXXXXXXXXX}
	right=54.218.19.145
	rightsubnet=10.100.100.0/24
	pfs=yes
	auto=start">/etc/ipsec.d/$NAME-to-core.conf
echo 'XXXXXXXXXXXXXXXXXXX 54.218.19.145: "HdbT.29tAxeSR-_gm4KLx77_pcg_3ZR8"' >/etc/ipsec.d/$NAME-to-core.secrets

echo '# Kernel sysctl configuration file for Red Hat Linux
#
# For binary values, 0 is disabled, 1 is enabled.  See sysctl(8) and
# sysctl.conf(5) for more details.

# Controls IP packet forwarding
net.ipv4.ip_forward = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.eth0.send_redirects = 0

# Controls source route verification
net.ipv4.conf.default.rp_filter = 1

# Do not accept source routing
net.ipv4.conf.default.accept_source_route = 0

# Controls the System Request debugging functionality of the kernel
kernel.sysrq = 0

# Controls whether core dumps will append the PID to the core filename.
# Useful for debugging multi-threaded applications.
kernel.core_uses_pid = 1

# Controls the use of TCP syncookies
net.ipv4.tcp_syncookies = 1

# Disable netfilter on bridges.
net.bridge.bridge-nf-call-ip6tables = 0
net.bridge.bridge-nf-call-iptables = 0
net.bridge.bridge-nf-call-arptables = 0

# Controls the default maxmimum size of a mesage queue
kernel.msgmnb = 65536

# Controls the maximum size of a message, in bytes
kernel.msgmax = 65536

# Controls the maximum shared segment size, in bytes
kernel.shmmax = 68719476736

# Controls the maximum number of shared memory segments, in pages
kernel.shmall = 4294967296

# Maximize console logging level for kernel printk messages
kernel.printk = 8 4 1 7
kernel.printk_ratelimit_burst = 10
kernel.printk_ratelimit = 5'>/etc/sysctl.conf
sysctl -p

# write first-boot.json
echo '{"run_list": [ "role[base]", "role[nat]" ]}' > /etc/chef/first-boot.json

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
sudo s3cmd -c /home/ubuntu/.s3cfg get s3://lmstaging-systems/validation.pem 
sudo mv validation.pem /etc/chef/validation.pem 

# write client.rb
(
sudo cat << 'EOP'
log_level :info
log_location STDOUT
chef_server_url 'https://chef.livemagic.internal'
validation_client_name 'chef-validator'
EOP
) > /etc/chef/client.rb

#Write Dynamic DNS keys
(
sudo cat << 'EOP'
key "$TAG.livemagic.internal." {
  algorithm hmac-md5;
  secret "4HV3EVtySGWGmy8IgWKqE+48sKOe96oX6db7h+LOmQ7e796ZenMamzD4 P93/7UXn4pDY/ePobYXpjyNLRa3n5g==";
};
EOP
) >/root/dns.key

#Add new DNS information to file
echo -e "server $DNSSERVER \n
debug yes \n
zone $TAG.livemagic.internal \n" >/root/addme.dns

OLDIP=$(dig $NAME.$TAG.livemagic.internal. +short)
if [ ! "${OLDIP}.." = ".." ];then
	echo -e "\n update delete $NAME.$TAG.livemagic.internal 60 A $OLDIP\n\n" >>/root/addme.dns
fi


echo -e "
update add $NAME.$TAG.livemagic.internal 60 A $MYIP \n

show \n
send" >> /root/addme.dns

echo "node_name \"$NAME\"" >> /etc/chef/client.rb
# Bootstrap chef

sudo nsupdate -k /root/dns.key -v /root/addme.dns
#rm -rf  /root/dns.key /root/addme.dns /home/ubuntu/.s3cfg

sudo nohup /usr/bin/chef-client -j /etc/chef/first-boot.json &>/root/chef-first-run.log &
