#!/usr/bin/perl

#Uses SQL Library
use Mysql;

#Requests sql password
print "Password, Mr Nubs?\n";
$password = "142536";

#Sql username and database
$db = Mysql->connect(localhost, license, root, $password);
$db->selectdb(license);

#Game threshold for sending email
$threshold = 2;

#Games to check licenses for
#@game=("cod4","ft","d2","bf2","hgl");
@game=("cod4");
#while (1){
$gamecounter="0";

for (@game)
	{
	print $game[$gamecounter];

	$sqlquery = "select count(*) from v3 where game = '$game[$gamecounter]'";
	$gamenum = $db->query($sqlquery);
	print $gamenum;
	$sqlquery = "select count(*) from v3 where game = '$game[$gamecounter]' and status = 'inuse'";
	$usecount = $db->query($sqlquery);
	print $usecount;
	$sqlquery = "select computer from v3 where game = '$game[$gamecounter]' and status = 'inuse'";
	@computer = $db->query($sqlquery);
	$computercount = scalar(@computer);

#This is what alerts you if all the games licenses are in use.
	if ($usecount >= ($gamenum - $threshold))
		{
		if ($usecount == $gamenum)
			{
			$sqlquery = "select * from withoutkey where game = '$game[$gamecounter]'";
			@querylist = $db->query($sqlquery);
			system("echo \"$game[$gamecounter] is out of licenses! FIX ME NOW DAMNIT!\@!\@!\@ \n@querylist \" |mail -s \"$game[$gamecounter] is out of licenses!\" 4088889940\@txt.att.com");
}
		else
			{
			system("echo \"$game[$gamecounter] is low on licenses, you should probably fix that soon \n@querylist \" |mail -s \"$game[$gamecounter] is low on licenses\" chandler_cord\@yahoo.com");
			} 
		}
#Checks to see if a given computer is using more then one license for a single game
	$computercheck = "0";
	while ($computercheck <= $gamenum)
		{
		if ($computer[$computercheck] == "")
			{
			print " **$computercheck $gamenum** the phantom strikes again! key marked in use, without a computer name";
			}
		else
			{
			$sqlquery = "select count(*) from v3 where game = '$game[$gamecounter]' and status = 'inuse' and computer = '$computer[$computercheck]'";
			$duplicatecheck = $db->query($sqlquery);
			if ($duplicatecheck > '1')
				{
				system("echo \"$computer[$computercheck] has more than one license of $game[$gamecounter] registered. They are greedy, and should be struck down.\" |mail -s \"Computer is using more then one license\" chandler_cord\@yahoo.com");
				}
			}
		$computercheck ++;
		}
	$gamecounter ++;
	}
system("sleep 60");
#}
