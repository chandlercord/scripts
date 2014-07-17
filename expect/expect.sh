#!/usr/bin/expect

set timeout -1

#send_user "Please enter ipbx password: \n"
#stty -echo
#expect_user -re "(.*)\n"
#stty echo
#send_user "\n"
#set ipbxpw "$expect_out(1,string)\r"
send_user "Please enter command: \n"
expect_user -re "(.*)\n"
send_user "\n"
set command "$expect_out(1,string)\r"

set ipbxpw "k16938ed177"
#set ipbxpw "Uzldk2;w"

#set host "192.84.16.197"
set host "soledad.euphnet.com"

spawn $env(SHELL)
send "\$ "
send "ssh -l ipbx $host\r"
#expect "(yes/no)"
#send "yes\r"
send "\$ "
expect "assword:"
send "\$ "
send "\n"
expect "ssword:"
#expect "ssword: "
send "$ipbxpw\n"
#send "blah\n"
send "$command\n"

