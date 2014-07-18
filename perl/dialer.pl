#!/usr/bin/perl

use strict;
use MIME::Lite;

#First command line argument
my $input = shift;

#Open the file in the command line arguement
open(INPUT, "$input") or die "Unable to open $input: $!";


#Declare time in GMT and add 1900 to the year
my ($seconds, $minutes, $hour, $day, $oldmonth, $oldyear, $dayofweek, $dayofyear, $dst) = gmtime(time);
my $hour1 = $hour+1;
my $hour2 = $hour+2;
my $year = $oldyear+1900;
my $month = "";
my $day1 = $day;

#If the month is less then 10, add a preceeding zero, else leave it alone
if ($oldmonth > 10) {
        next;
} else {
        $month = "0$oldmonth";
}

#If the hour is 23, change hour1 to 00 and hour2 to 01, following suit with our log formatting
if ($hour == 23) {
	$day1 = $day+1;
        $hour1 = "00";
	$hour2 = "01";
} else {
	;
}

#If the hour is 22, change hour1 to 23 and hour2 to 00.
if ($hour == 22) {
	$day1 = $day+1;
        $hour1 = "23";
	$hour2 = "00";
} else {
	;
}


#
#Sample lines from CRM formatted file.
#
#Carrier,DID,City,State,Rate Center,Country Code
#L3,13308994369,,OH,GREENSBURG,1
#L3,13308638014,,OH,MALVERN,1

#Remove /tmp/list
unlink("/tmp/list");


#Grab just the numbers, adding a prefacing 1.
while (<INPUT>) {
	chomp;
	my($carrier,$did,$city,$state,$rc,$cc) = split(/,/, $_);
	next if m/DID/i;
	#Add numbers to /tmp/list.
	open(OUTFILE, '>> /tmp/list');
	print OUTFILE "1$did\n";
	close(OUTFILE);
	}

open(MODEMS, "dialer.modems") or die "Unable to open modems.list: $!";
open(NUMBERS, "/tmp/list") or die "Unable to open list: $!";

my @numbers = <NUMBERS>;
my @modems = <MODEMS>;

chomp(<MODEMS>);
chomp(<NUMBERS>);

while (<NUMBERS>) {}
my $linecount = $.;

my $split = int($linecount / 16);
my $lastfile = ($split % 16) + $split;
my @print = "";
my $count = "";
my $filename;
for (@modems ) {
	#$filename = substr($modems[$count], 0, - 1).".list";
	$filename = $modems[$count].".list";
        open(MODEM, ">$filename");
        if ( $count != 15 ) {
                $count++;
                @print = splice(@numbers, 0, $split);
                print MODEM @print;
                } else {
                @print = splice(@numbers, 0, $lastfile);
                print MODEM @print;
                }
        close(MODEM);
        }

open(RUN, ">runfile.sh") or die "Problem: $!"; 
$count = "";
for (@modems ) {
	print RUN "scp $modems[$count].list ops-wardialer2:~/dialer101\n";
	$count++;
	}
$count = "";
for (@modems ) {
	print RUN "ssh ops-wardialer2 ~adminscripts/bin/verifydid $modems[$count] ~adminscripts/dialer101/$modems[$count].list &\n";
	print RUN "sleep 5\n";
	$count++;
	}

system("chmod +x ./runfile.sh");
system("bash ./runfile.sh > output.out 2>output.out");

while (`cat output.out | grep "Run" | wc -l` != 16) {
        sleep 10;
        }

sleep 120;
system("bash ./runfile.sh > output.out 2>output.out");

while (`cat output.out | grep "Run" | wc -l` != 16) {
        sleep 10;
        }

print "Dialing completed.\n";
#my $to = "didorders\@packet8.net";
my $to = "ccord\@8x8.net";
my $from = "adminscripts\@8x8.com";
my $subject = "Your numbers are dialed, go verify them.";
my $message = "Don't forget the numbers.";


my $msg = MIME::Lite->new(
       From => $from,
       To => $to,
       Subject => $subject,
       Data => $message
);

$msg->send();



