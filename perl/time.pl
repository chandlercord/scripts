#!/usr/bin/perl -w

use strict;
use Data::Dumper;
my $epoch = time;
my ($seconds, $minute, $hour, $day, $time4, $year, $time6, $time7, $time8) = localtime();
my $ltime = localtime;
$year = $year + 1900;

print $epoch . "\n";
print "$ltime\n";
print "$seconds seconds\n$minute minutes \n$hour hours\n";
print "$day day\n$time4\n$year year\n$time6\n$time7\n$time8\n";

print Dumper localtime;
