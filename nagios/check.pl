#!/usr/bin/perl

use strict;
use warnings;

my $start='CINFILE=$';
my $stop='^#$';
my $filename;
my $output;
my $counter=1;
my $found=0;

while (<>) {

	# Find block of lines to extract                                                           
	if( /$start/../$stop/ ) {

		# Start of block                                                                       
		if( /$start/ ) {
			$filename=sprintf("boletim_%06d.log",$counter);
			open($output,'>>'.$filename) or die $!;
		}
		# End of block                                                                         
		elsif ( /$end/ ) {
			close($output);
			$counter++;
			$found = 0;
		}
		# Middle of block                                                                      
		else{
			if($found == 0) {
				print $output (split(/ /))[1];
				$found=1;
			}
			else {
				print $output $_;
			}
		}

	}
# Find block of lines to extract                                                           

}
