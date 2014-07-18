#!/bin/sh

#scp required files over
cd /tmp
scp us0401ats001:/nas/platform/platformcacti.tar.gz .

#Install cacti and percona-server-devel
yum -y install cacti  Percona-Server-devel-51.x86_64

#Copy cacti directory and chown to cacti
\cp -r var/www/cacti/ /var/www/
chown -R cacti.cacti /var/www/cacti; chown -R cacti.cacti /var/www/cacti/*

#Download and compile net-snmp
cd /tmp
wget http://sourceforge.net/projects/net-snmp/files/net-snmp/5.7/net-snmp-5.7.tar.gz/download
tar xzvf net-snmp-5.7.tar.gz 
cd net-snmp-5.7
./configure
make
make install

#Download and compile spine
cd /tmp
wget http://www.cacti.net/downloads/spine/cacti-spine-0.8.7g.tar.gz
tar xvzf cacti-spine-0.8.7g.tar.gz
cd cacti-spine-0.8.7g
./configure
make
make install

#Create /etc/spine.conf and copy spine binary to correct location
echo -e "DB_Host\t         localhost\nDB_Database\t     cacti\nDB_User\t         cacti\nDB_Pass\t         paloalto1two3\nDB_Port\t         3306\nDB_PreG\t         0\n" > /etc/spine.conf
cp /usr/local/spine/bin/spine /usr/bin/spine

#Create cacti user and database, and import cacti DB.
mysql -u root -proot -e "create database cacti;"
mysql -u root -proot -e "GRANT ALL ON cacti.* TO 'cacti'@'localhost' IDENTIFIED BY 'paloalto1two3';"
cd /tmp
mysql -u root -proot cacti < platformcacti.sql

#Create httpd cacti config
echo -e "Alias /cacti/ /var/www/cacti/\n \
<Directory /var/www/cacti/>\n \
    DirectoryIndex index.php\n \
    Options -Indexes\n \
    AllowOverride all\n \
    order deny,allow\n \
    deny from all\n \
    allow from ALL\n \
    AddType application/x-httpd-php .php\n \
    php_flag magic_quotes_gpc on\n \
    php_flag track_vars on\n \
</Directory>" >/etc/httpd/conf.d/cacti.conf

#create cacti rsa
mkdir /etc/cacti
echo -e "-----BEGIN RSA PRIVATE KEY-----\n \
MIIEoQIBAAKCAQEAwlTTOoh4OLc7cybqRgkjvfx2UpRtaSo+yn2AlFZVrybnM7dT\n \
2s+7x86XByo7DZy+mO1i9wTvwFAtkIqlZ5tG41xouMeGyS36THol6i1unrlRdDq8\n \
hO34oBs+NEF318nrnH5YZF4Z2WOrcwizzVIqGTx3N6p2JfFGjKeVwtipF19aKiR6\n \
r4fui+nPPtbPYWth1Rj/Jh0V81hS8BAfgL/TW27YSADB5NjjWYa5xX4O5h7RXawx\n \
2EHjvXq8YqDBS9Q/B6J9b2NKArQLthcRe9fehoq1DFlutECRytAzV+1H/RZTfTRd\n \
fE4cTRAYnQrfcBT0ae1UAoA52cQMDaFrkVRHnQIBIwKCAQEAlemqQxjRxVomjAgT\n \
z6Cmiz8ZcueHmkUpH90orPIk15MKIJS9B+IUhDGntRHzCoA7QsXBX3jWNUUqdtFb\n \
Bsg9/9mSnSw0xxTXB8vxXOE4FAtNdut7fH0QQP8Supjna/OJ3x+jRhy02uZ88lcr\n \
nmP0lyAEMkGrmZzepwTv33PwJ/fBeK0oCPCmbaB9mE2xwEq52lLy86cABJxtkNYJ\n \
CK5/VFHRbLOExgD7kgV/EtgtyUgmJDbpIZ9dcABRnyu14iwnQ97mkEgHshhEtWHP\n \
hDfO1T9o5daWbmaUz0rHsmplrSbe88wRkgPPFa3+Wu8PtfSS9gxwc84x4ENeQZr8\n \
X1IMhwKBgQDjrYW5jJwxsjLFEfo1MWIWcgeeO31CR6Xl310umztEB8wgiuFsOTm2\n \
VRQt82kl1Qgw2IHlInNMdtsT5119ohYxQslZMKOU0gyZ4iFSX5gG1xbg3gFMds2z\n \
xslRU1U3z+zdFaSHWNTOQPkbdCbC1U8uQKkRP0E/OpWk2E1ABNn8NwKBgQDagV96\n \
Rr1D7MqNSvygznkFIiEcf18MiUZ2vT6sTAqn5lUaCkmWl/y3gAybPmT5kOiCCl5g\n \
3446mP4PRKJOaByFiU/mZ0XkGmIPR6ZcxjBjRa/abLO+DSbHx+hQ7eg3ClXjnU5q\n \
B2Fnh7CzcKS8Yw15bw41u1mdhfOEulva6vz4ywKBgG6WHGFwLpvLlQCiVPVD3y95\n \
NuZ0qo3oSUPEQzPk/4dxgGeT6dV64YRyd4QIg4dneQHIPxeFwvlBC1LPdo16nRCc\n \
yDKimJi9y5szUgNwQob6wfgxURaC2PDrhlqzcojStOBpmQ6KO3ofjvAT2FABNRZ3\n \
LYwIx+uC2vhLzcACWz/9AoGAdp4AoXbbxcmvyQtzMrk6Yd9TzaQ66YxZc6iPvJ5O\n \
7W5otl1bJd16j4AG1+6r1++UKVYV+hL1cERsqTPjFJ7q6WfMSeBKgyRD3Gi5ZZAo\n \
5W75ECxhkw50I09DmaW4kuhaguBdxIep576wYWkI+I2K+MdCOm0EwzoWe0CYQ6Qi\n \
7XUCgYBIleckYRtWaod8KHLudnrB9MRTVpODf7lhADLKnut7DoyPlydqXOj12a92\n \
O1B96D38UvB7AjKvTCOId9wgUEkLkpbYOWvVSzXcRAiBP5fIGzhsWEFnZZ9T2QLI\n \
irF0UMXDt0IXztToBJOreV17bFrC/Ufvok8ey0SZtX03HCbR3w==\n \
-----END RSA PRIVATE KEY-----" >>/etc/cacti/id_rsa

chown cacti.cacti /etc/cacti/id_rsa
chmod 600 /etc/cacti/id_rsa
