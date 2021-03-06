#!/bin/awk -f
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# This script will parse nagios's status.log file usually located in /usr/local/nagios/var/
# or /usr/local/groundwork/nagios/var/ (if using groundwork) and is supposed to look for all services
# that have notifications turned off.  This can be useful to remind a busy sysadmin
# of the services disabled in the middle of the night that he/she may have forgotten.
#
BEGIN { header=0;
	FS="=";
}

/^[[:space:]]*info {[[:space:]]*$/ {
        codeblock="info";
}

/^[[:space:]]*programstatus {[[:space:]]*$/ {
        codeblock="program";
        notifications_enabled="";
}

/^[[:space:]]*hoststatus {[[:space:]]*$/ {
        codeblock="host";
}

/^[[:space:]]*servicestatus {[[:space:]]*$/ {
        codeblock="service";
}

/^[[:space:]]*enable_notifications=/ {
        notifications_enabled=$2;
}

/^[[:space:]]*}[[:space:]]*$/ {
		if (codeblock=="program" && notifications_enabled=="0") {
				if (header==0) {
					print "\n******************\nNotifications have been disabled globally!!!!!!!\n";

					header=1;
		}
				print host_name;
        }
}

