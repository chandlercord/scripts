#!/usr/bin/perl

my $input = shift;
open(INPUT, "$input") or die "Unable to open $input: $!";

my($name,$ext) = split(/\./, $input);
$output = "$name.scope";
open(OUTPUT, ">", "$output") or die "Unable to open $output: $!";


while (<INPUT>) {
        chomp;
        next if m/First/i;
	next if m/---/i;
        my($des,$gateway,$firstip,$lastip,$slash) = split;
	my($octet1,$octet2,$octet3,$octet4) = split(/\./, $gateway);
	$subnet = "$octet1.$octet2.$octet3.0";
	if ($slash == "24") { $netmask = "255.255.255.0"} ;
	print OUTPUT "#$des\n\tsubnet $subnet netmask $netmask {\n\toption ntp-servers 69.80.61.150 , 69.80.61.151;\n\toption domain-name-servers 69.80.61.150 , 69.80.61.151;\n\toption routers $gateway;\n\trange $firstip $lastip;\n}\n";
}

close(OUTPUT);
