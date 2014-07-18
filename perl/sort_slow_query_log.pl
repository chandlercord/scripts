#!/usr/bin/perl

#############################################################################
#                                                                           #
# This script is used sort MySQL slow query logs from Percona 5.5 databases #
#                                                                           #
# Written by: Chandler Cord                                                 #
# chandlercord@gmail.com                                                    #
#                                                                           #
#############################################################################

use strict;
use Data::Dumper;
use Sys::Hostname;

my $slow_log = "/Users/ccord/scripts/perl/slow.log";

open(INPUT, $slow_log) or die "Unable to open $slow_log: $!";

my $block;
my $line;
my $time;
my $thread_id;
my $query_time;
my $bytes;
my $query;
while (<INPUT>) {
  chomp;      # strip record separator
  $line = $_;
  if ($line =~ m/# User@Host:/) {
    $block = "query";
    $time = $line;
    print $block . "\n" if $VERBOSE eq "1";
  #} else {
  #  undef $block;
  }
  if ($block eq "query") {
    next unless $line =~ m/# Thread_id:|# Query_time:|# Bytes_sent:|SET timestamp/;
    $thread_id = $line if /Thread_id/;
    $query_time = $line if /Query_time/;
    $bytes = $line if /Bytes_sent/;
    $query = $line if /INSERT|REPLACE|UPDATE|SELECT|DELETE|VALUES|SET|WHERE|IN|RLIKE|MATCH|AND|OR|DISTINCT|MAX/i;
    #push( @{$hash{$host}{'service'}}, $service) if $service && ($notif = /notifications_enabled=0/);
  #} elsif ($block eq "hoststatus") {
   # next unless $line =~ m/host_name|notifications_enabled/;
   # $notif = $line if /notifications_enabled/;
   # $host = $line if /host_name/;
   # push (@hosts, $host) if $host && ($notif = /notifications_enabled=0/);
  }

}
