#!/opt/local/bin/perl -w

use strict;

my @names=print `sudo find /Users/ccord -type d -maxdepth 1 | grep -v "ccord\$"` . "\n";
#my @names=system('sudo find /Users/ccord -type d -maxdepth 1 | grep -v "ccord$"') "\n";

my ( $line, $dirSize );
foreach (@names) {
#  chomp;
  $line = $_;
  $dirSize=system("sudo du -sk $line");
  print $line;
  print $dirSize;
}
