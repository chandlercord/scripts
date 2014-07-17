#!/usr/bin/perl

use strict;
use Data::Dumper;


open(INPUT, "/home/ccord/scripts/nagios/status.dat") or die "Unable to open /home/ccord/scripts/nagios/status.dat: $!";

my $text;
my $result;
my $host;
my $line;
my $f;
my ($total1, $total2, $total3, $total4, $host, $notif, $service, @hosts, $hosts, $nagios,$hash_ref,$hash, $key, %host);
my %hash = ();

while (<INPUT>) {
    chomp;      # strip record separator
    if(/\}/) { $f=0;}
    if (/servicestatus/) {
        s/.*servicestatus//g;
        $f=1;
    }
    
    $line = $_;
    next unless $line =~ m/host_name|service_description|notifications_enabled/;
    my $service = $line if /service_description/;
    $nagios = $line if /service_description/;
    $notif = $line if /notifications_enabled/;
    $host = $line if /host_name/;
    $nagios =~ (s/ //g);
    $nagios =~ (s/.*=//g);
    $service =~ s/.*=//g;
    $host =~ s/.*=//g;

    push( @{$hash{$host}{'service'}}, $service) if $service;

}

foreach $host(sort keys %hash) {
	print "$host\n";
	foreach my $services (@{$hash{$host}{'service'}}){
		print "\t$services\n";
	}
}
