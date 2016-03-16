#!/usr/bin/perl

use strict;

my ($total1, $total2, $total3, $total4, $iqName, $log_length, $count, $i, $line, $avg);
$iqName = @ARGV[0];
#print "$iqName";

#Known IQ names##
#asdf_registration
#stats
#addressbook
#asdf_invite
#asdf_validation
#device_token
#filter_account
#filter_contacts
#call_log
#turnserver
#dynamic_cfg
#oob_notification
################

die "no iq name" unless $iqName;
open(LOG,"/local/tomcat/logs/asdfgear-videomail.log") or die "Unable to open logfile:$!\n";
my @log_lines;
while(<LOG>){
	my $line = $_;
#	next unless $line =~ m/com.asdf.stats.log.IQStatsTracker/;
	next unless $line =~ m/${iqName}.*totalCount/;
	push(@log_lines, $line);
}
$log_length = scalar(@log_lines);
$count = 0;
for($i=$log_length-5;$i < $log_length;$i++) {
	$line = $log_lines[$i];
        #print "$line";
	$line =~ m/.*?"totalCount":(\d+),"qt":(\d+),"qtMin":(\d+),"qtMax":(\d+)/ ;
	$total1 += $1;
        if ($count == 0) {
          $total2 = $2;
          $total3 = $3;
        } else {
          if ($total2 > $2) {
            $total2 = $2;
          }
          if ($total3 < $3) {
            $total3 = $3;
          }
        }
        $total4 += ($1 * $4);
        $count += 1;
}
#print "$total4: $total1\n";
if ($total1 > 0) {
  $avg = int($total4 / $total1);
  print "$total1\n$total2\n$avg\n$total3";
} else {
  print "0\n0\n0\n0";
}
close(LOG);
