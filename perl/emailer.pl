#!/usr/bin/perl

use strict;
use Log::Log4perl qw(:easy);

# Initialize Logger
my $log_conf = q(
   log4perl.rootLogger              = DEBUG, LOG1
   log4perl.appender.LOG1           = Log::Log4perl::Appender::File
   log4perl.appender.LOG1.filename  = /local/inactiveemail/email.log
   log4perl.appender.LOG1.mode      = append
   log4perl.appender.LOG1.layout    = Log::Log4perl::Layout::PatternLayout
   log4perl.appender.LOG1.layout.ConversionPattern = %d %p %m %n
);

Log::Log4perl::init(\$log_conf);
my $logger = Log::Log4perl->get_logger();
 
$logger->info("$0 started.");

#Declare some static variables.
my $SOURCEFILE="/local/inactiveemail/test.dat";
my $LOGFILE="/local/inactiveemail/email.log";
my $COOKIE="/local/inactiveemail/.cookie";
my $flist="/local/inactiveemail/failedlist.csv";
my $EID="204525";
my $SUCCESS="0";
my $FAILURE="0";

unlink $COOKIE;

my $LOGIN=`curl -s -k -c $COOKIE 'https://ebm.cheetahmail.com/api/login1?name=tango_apiuser&cleartext=w\@LrT3G0d' | tr -d '\r' |head -n 1`;
chomp $LOGIN;

if ($LOGIN eq "OK") {
	$logger->info("API login successful. Response: $LOGIN");
} else {
        $logger->error("API login failed with the following message: $LOGIN. Retrying in 10 seconds");
	sleep 10;
	my $LOGIN_RETRY=`curl -s -k -c $COOKIE 'https://ebm.cheetahmail.com/api/login1?name=tango_apiuser&cleartext=w\@LrT3G0d'`;
	chomp $LOGIN;
	if ($LOGIN_RETRY ne "OK") {
		$logger->logdie("API login failed again, exiting.\n\n");
	} else {
		$logger->info("API login successful");
	}
}

#Open up source file, remove stale failed list and open new one
open(FAILEDLIST, ">> $flist") or $logger->logdie("Unable to open $flist: $!\n\n");
$logger->info("Opened $flist");
open(REPORT, "$SOURCEFILE") or $logger->logdie("Unable to open $SOURCEFILE: $!\n\n");
$logger->info("Opened $SOURCEFILE");


while (<REPORT>) {
	#remove newline and split into variables.
	chomp;
	my($fname,$lname,$recipientemail) = split(/,/, $_);
	#Fire off call to Cheetahmail
	my $SENDEMAIL=`curl -s -k -b $COOKIE "https://ebm.cheetahmail.com/ebm/ebmtrigger1?aid=2086125692&eid=$EID&email=$recipientemail&FNAME=$fname&LNAME=$lname"`;
	chomp $SENDEMAIL;
	if ($SENDEMAIL eq "OK") {
		$logger->info("API response: $SENDEMAIL.");
		$logger->info("email sent to $recipientemail from $fname $lname.");
		$SUCCESS++
	} else {
		#Because Cheetahmail sucks and their error message ends with "\n ^M" we have to chop thrice.
		chop $SENDEMAIL;
		chop $SENDEMAIL;
		chop $SENDEMAIL;
		$logger->error("API error: $SENDEMAIL.");
		$logger->error("Failed sending email to $recipientemail from $fname $lname.");
		#Logs failed emails to list in the correct format for later use.
		print FAILEDLIST "$fname,$lname,$recipientemail\n";
		$FAILURE++
	}
}

close(REPORT) or $logger->logdie("Unable to close $SOURCEFILE: $!\n\n");
close(FAILEDLIST) or $logger->logdie("Unable to close $flist: $!\n\n");


if ($FAILURE >= "1") {
	$logger->info("Run completed. $SUCCESS successful emails sent and $FAILURE failed emails.");
	$logger->info("Failed emails logged in $flist\n\n");
} else {	
	$logger->info("Run completed. $SUCCESS successful emails sent and $FAILURE failed emails.\n\n");
}

exit 0
