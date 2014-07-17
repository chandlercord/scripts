#!/usr/bin/perl

use strict;

open (FILE

my $depth = 0;
my $out = "";
my @list=();
foreach my $fr (split(/([{}])/,$data)) {
    $out .= $fr;
    if($fr eq '{') {
        $depth ++;
    }
    elsif($fr eq '}') {
        $depth --;
        if($depth ==0) {
            $out =~ s/^.*?({.*}).*$/$1/s; # trim
            push @list, $out;
            $out = "";
        }
    }
}
print join("\n==================\n",@list);
