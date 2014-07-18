#!/usr/bin/perl

use strict;
use Data::Dumper;
use Sys::Hostname;

my $VERBOSE="0";

if (@ARGV == 0) {
	print "Please specify host or service:\n$0 <host> or $0 <service>\n";
	exit 1;
}

open(INPUT, "/var/nagios/status.dat") or die "Unable to open /home/ccord/scripts/nagios/status.dat: $!";

my $text;
my $result;
my $host;
my $line;
my $f;
my $type=$ARGV[0];
my ($total1, $total2, $total3, $total4, $host, $notif, $service, @hosts, $hosts, $nagios,$hash_ref,$hash, $key, %host, $status, $serviceplus, $hash1, $host1, %hash1);
my %hash = ();
my $loc = hostname;

if ($loc =~ m/us01/i) {
	$loc = "us01";
} elsif ($loc =~ m/us04/i) {
	$loc = "us04";
}

my $nagiosurl = "nagios.$loc.tangome.gbl";

if ($type =~ m/service/i) {
	$status="servicestatus";
} elsif ($type =~ m/host/i) {
	$status="hoststatus";
} else {
	print "Please specify host or service:\n$0 <host> or $0 <service>\n";
	exit 1
}

my $block;
while (<INPUT>) {
    chomp;      # strip record separator
    $line = $_;
 	if ($line =~ m/servicestatus/) {
 	#if ($line =~ m/^(\w+)\s+?\{$/) {
		$block = "servicestatus";
		print $block . "\n" if $VERBOSE eq "1";
	} elsif ( $line =~ m/hoststatus/i) {
		$block = "hoststatus";
	} elsif ( $line =~ m/^\s+?\}$/) {
		undef $block;
	}
	if ($block eq "servicestatus") {
		next unless $line =~ m/host_name|service_description|notifications_enabled/;
		$service = $line if /service_description/;
		$serviceplus = $line if /service_description/;
		$nagios = $line if /service_description/;
		$notif = $line if /notifications_enabled/;
		$host = $line if /host_name/;
		$nagios =~ (s/ //g);
		$nagios =~ (s/.*=//g);
		$service =~ s/.*=//g;
		$service =~ s/ /+/g;
		$serviceplus =~ s/ /+/g;
		$host =~ s/.*=//g;
		push( @{$hash{$host}{'service'}}, $service) if $service && ($notif = /notifications_enabled=0/);
	} elsif ($block eq "hoststatus") {
		next unless $line =~ m/host_name|notifications_enabled/;
		$notif = $line if /notifications_enabled/;
		$host = $line if /host_name/;
		$nagios =~ (s/ //g);
		$nagios =~ (s/.*=//g);
		$host =~ s/.*=//g;
		push (@hosts, $host) if $host && ($notif = /notifications_enabled=0/);
	}

}
my $hostcount = 0;
my $hostcount1 = 0;
my $servicecount = 0;

foreach (@hosts) {
	$hostcount1++;
}

foreach $host(sort keys %hash) {
	$hostcount++;
	foreach my $services (@{$hash{$host}{'service'}}) {
		$servicecount++;
	}
}

print "To: ccord\@tango.me\nSubject: Nagios Service Check\nContent-Type: text/html; charset=\"us-ascii\"<html>\n";
print "<b>There are $servicecount service notifications disabled and $hostcount1 host notifications disabled. <a href=\"https://$nagiosurl/\">$loc Nagios</a></b><br />";
print "<br />******************<br />\n";
print "The following hosts have notifications disabled:<br /><br />\n";
foreach (@hosts) {
	print "<b><a href=\"https://$nagiosurl/nagios/cgi-bin/extinfo.cgi?type=1&host=$_\">$_</a></b><br />\n";
}
print "<br />******************<br />\n";
print "The following servies have notifications disabled:<br /><br />\n";
foreach $host(sort keys %hash) {
	print "<b><a href=\"https://$nagiosurl/nagios/cgi-bin/extinfo.cgi?type=1&host=$host\">$host</a></b><br />\n";
	foreach my $services (@{$hash{$host}{'service'}}){
		$service = $services;
		$service =~ s/\+/ /g;
		print "&nbsp;&nbsp;&nbsp;&nbsp;<a href=\"https://$nagiosurl/nagios/cgi-bin/extinfo.cgi?type=2&host=$host&service=$services\">$service</a><br />\n";
	}
	print "<br />";
}
print "</html>\n";
