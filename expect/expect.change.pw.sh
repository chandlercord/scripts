#!/usr/bin/expect -f 
set timeout -1
send_user "Root Password please: \n"
stty -echo
expect_user -re "(.*)\n"
stty echo
send_user "\n"
set pass "$expect_out(1,string)\r"
send_user "New ipbx Password? \n"
expect_user -re "(.*)\n"
send_user "\n"
set newipass "$expect_out(1,string)\r"
send_user "New Root Password? \n"
expect_user -re "(.*)\n"
send_user "\n"
set newpass "$expect_out(1,string)\r"
#set host [lindex $argv 0]
#set command "[lindex $argv 1]\r"
for {set i 0} {$i<$argc} {incr i} {

set timeout 15
set host [lindex $argv $i]
spawn $env(SHELL)
expect "\$ "
send "ssh $host\r"
expect "\$ "
send "su -\r"
expect "assword"
send $pass
expect "#"
send "passwd\r"
expect "ssword:"
send $newpass
expect "ssword:"
send $newpass
expect "#"
send "passwd ipbx\r"
expect "ssword:"
send $newipass
expect "ssword:"
send $newipass
expect "#"
close
}
