#!/usr/bin/perl -w

use strict;

my $LIST="/tmp/list";

open(INPUT, "$LIST") or die "Unable to open $LIST: $!";

my @ARRAY = <INPUT>;

my $count = "0";
for (@ARRAY ) {
	my $randomelement = $ARRAY[rand @ARRAY];
        #print "Number $count: $ARRAY[$count]\n";
        print "Number $count: $randomelement\n";
        $count++;
}
