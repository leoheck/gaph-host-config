#!/bin/bash

# Leandro Sehnem Heck (leoheck@gmail.com)

# CRONTAB CONFIGURATION
# This script creates periodic tasks to be executed by the cron

# http://www.cyberciti.biz/faq/how-do-i-add-jobs-to-cron-under-linux-or-unix-oses/
# * * * * * command to be executed
# - - - - -
# | | | | |
# | | | | ----- Day of week (0 - 7) (Sunday=0 or 7)
# | | | ------- Month (1 - 12)
# | | --------- Day of month (1 - 31)
# | ----------- Hour (0 - 23)
# ------------- Minute (0 - 59)

key="$1"


# Test (1x/min)
# * * * * * touch /tmp/gaph-upgrade-\$(date +\%Y-\%m-\%d:\%H:\%M)

# Upgrade gaph config from github (1x/week)
# 0 0 * * 0 /usr/bin/upgrade-gaph-host

### Create a service to recober root contab for each restart

install_crontab()
{
	echo "  - Installing cronjobs"

	# BACKUP
	if [ ! -f /var/log/gaph/cron.bkp ]; then
		crontab -l > /var/log/gaph/cron.bkp 2> /dev/null
	fi

	#===========================
	read -r -d '' CRONCONF <<-EOM

	# TESTING (1x/day)
	0 0 * * * root /usr/bin/upgrade-gaph-host

	# Keep /etc/salt/minion updated and running (1x/day)
	0 2 * * * echo "$(hostname)" > /etc/salt/minion_id; sed -i "s/^[#]*master:.*/master: rodos/g" /etc/salt/minion; service salt-minion restart

	# Update /etc/hosts file (4x/day)
	30 7,12,18,23 * * * /soft64/admin/scripts/update-hosts.sh

	# Keep SGE running (1x/hour)
	0 * * * * root /etc/init.d/sgeexecd-ubuntu start > /dev/null 2>&1

	# Remove files older than n-days in /sim folder (1x/day)
	#0 2 * * * root find /sim/ -mtime +25 -exec rm {} \;

	# Backup main local user (UID=1000) files
	# 0 2 * * * root rsync /home/.$USER-bkp (incremental..only diffs..)

	EOM
	#===========================

	echo "$CRONCONF" | crontab -

	
	#===========================
	read -r -d '' INITSCRIPT <<-EOM
	
	# Ubuntu upstart file at /etc/init/gaph.conf
	# Created by Leandro Heck
	
	# Verifying if this script works
	# init-checkconf /etc/init/gaph.conf
	
	# Some basics to use the upstart (not required by my script)
	# sudo service <servicename> <control>
	
	description "This script restores the default GAPH cronjob to keep the host updated with the user mess with things"
	author "Leandro Heck"
	
	# pre-start script
	# end script
	
	start on runlevel [2345]
	stop on runlevel [06]
	
	script
	
	## RESTORE (ROOT) ORIGINAL CRONTAB
	
	CRONCONF="
	# Upgrade HOST (1x/day)
	0 0 * * * root /usr/bin/upgrade-gaph-host
	
	# Keep /etc/salt/minion updated and running (1x/day)
	0 2 * * * echo "$(hostname)" > /etc/salt/minion_id; sed -i \"s/^[#]*master:.*/master: rodos/g\" /etc/salt/minion; service salt-minion restart
	
	# Update /etc/hosts file (4x/day)
	30 7,12,18,23 * * * /soft64/admin/scripts/update-hosts.sh
	
	# Keep SGE running (1x/hour)
	0 * * * * root /etc/init.d/sgeexecd-ubuntu start > /dev/null 2>&1
	"
	echo "$CRONCONF" > /var/log/gaph/crontab
	
	echo "$CRONCONF" | crontab -
	
	exit 0
	
	end script
	
	# pre-stop script
	# end script

	EOM
	#===========================

	echo "$INITSCRIPT" > /etc/init/gaph.conf

}

remove_crontab()
{
	echo "  - Removing cronjobs"

	# Restore backup
	if [ -f /var/log/gaph/cron.bkp ]; then
		cat /var/log/gaph/cron.bkp > crontab
	else
		crontab -r
	fi
	
	# Remove init script
	rm -rf /etc/init/gaph.conf
}

case $key in

	-i|--install)
	install_crontab
	exit 0
	;;

	-r|--remove)
	remove_crontab
	exit 0
	;;

	*)
	echo "Unknonw option"
	exit 1

esac
