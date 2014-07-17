#!/usr/bin/expect

set passwd "s0b3yourself2"

set host [lrange $argv 0 0]

#spawn ssh -o StrictHostKeyChecking=no ns2-eqix-sjo hostname
spawn ssh -o StrictHostKeyChecking=no $host hostname
expect "dsa':"
send "$passwd\r"
expect "\$ "

