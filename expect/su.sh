#!/usr/bin/expect -f 

set passwd "w0whm1dg"

spawn $env(SHELL)
expect "\$"
send "su -\r"
expect "Password:"
send "$passwd\r"
expect "#"
send "echo blah\r"
send "touch /tmp/expect\r"
close


set user "ipbx"
set passwd "Uzldk2;w"
set host "8.5.248.233"

spawn $env(SHELL)
expect "\$"
#send "echo  -l $user $host\r"
send "ssh -l $user $host\r"
expect "(yes/no)"
send "yes\r"
expect "dsa':"
send "\r"
expect "assword:"
send "$passwd\r"
expect "#"
send "ls -lah\r"



close
