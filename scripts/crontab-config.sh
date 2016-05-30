#!/bin/bash

# Leandro Sehnem Heck (leoheck@gmail.com)

# CRONTAB CONFIGURATION
# This script creates periodic tasks to be executed by the cron

#==============================================================================
crontab << EOF

# Test (1x/min)
# * * * * * touch /tmp/gaph-upgrade-\$(date +\%Y-\%m-\%d:\%H:\%M)

# Upgrade host from github (using 1x/min for tests only)
* * * * * /usr/bin/upgrade-gaph-host

# Update /etc/hosts file (4x/day)
#30 7,12,18,23 * * * /soft64/admin/scripts/update-hosts.sh

# Always keep SGE running (1x/hour)
#0 * * * * root /etc/init.d/sgeexecd-ubuntu start > /dev/null 2>&1

# Keep /etc/salt/minion updated (1x/hour)
#0 * * * * root sed -i "s/^[#]*master:.*/master: rodos/g" /etc/salt/minion
#1 * * * * root echo "$hostname" > /etc/salt/minion_id
#2 * * * * root

# Remove files older than n-days in /sim folder (1x/day)
#0 2 * * * root find /sim/ -mtime +25 -exec rm {} \;

# Backup main local user (UID=1000) files
# 0 2 * * * root rsync /home/.$USER-bkp (incremental..only diffs..)

EOF
#==============================================================================
