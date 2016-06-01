#!/bin/bash

# Leandro Sehnem Heck (leoheck@gmail.com)

# MAIN SCRIPT TO CONFIGURE INSTALL GAPH CONFIGS

# GITHUB REPOSITORY CONFIG
REPO="gaph-host-config"
BRANCH="ubuntu-16.04"

GITHUB="https://github.com/leoheck/$REPO/archive/"
PKG=$BRANCH.zip

PROJECTDIR=/tmp/$REPO-$BRANCH

export PATH=./scripts:$PATH
export PATH=$PROJECTDIR/scripts:$PATH

mkdir /var/log/gaph/

# Ctrl+c function to halt execution
control_c()
{
	clear
	echo -e "\n$0 interrupted by user :(\n"
	kill -KILL $$
}

trap control_c SIGINT

# Use colors only if connected to a terminal which supports them
if which tput >/dev/null 2>&1; then
	ncolors=$(tput colors)
fi

if [ -t 1 ] && [ -n "$ncolors" ] && [ "$ncolors" -ge 8 ]; then
	RED="$(tput setaf 1)"
	GREEN="$(tput setaf 2)"
	YELLOW="$(tput setaf 3)"
	BLUE="$(tput setaf 4)"
	BOLD="$(tput bold)"
	NORMAL="$(tput sgr0)"
else
	RED=""
	GREEN=""
	YELLOW=""
	BLUE=""
	BOLD=""
	NORMAL=""
fi

# Only enable exit-on-error after the non-critical colorization stuff,
# which may fail on systems lacking tput or terminfo
set -e

# Prevent the cloned repository from having insecure permissions. Failing to do
# so causes compinit() calls to fail with "command not found: compdef" errors
# for users with insecure umasks (e.g., "002", allowing group writability). Note
# that this will be ignored under Cygwin by default, as Windows ACLs take
# precedence over umasks except for filesystems mounted with option "noacl".
umask g-w,o-w

# Check for super power
if [ "$(id -u)" != "0" ]; then
	echo -e "\n${YELLOW}Hey kid, you need superior powers, Go call your father.${NORMAL}\n"
	exit 1
fi

main()
{
	if [ -f $PKG ]; then
		printf "%s  Removing previews /tmp/$PKG ...%s\n" "${BLUE}" "${NORMAL}"
		rm -rf /tmp/$PKG
	fi

	printf "%s  Donwloading an updated $PKG from github in /tmp ...%s\n" "${BLUE}" "${NORMAL}"
	wget $GITHUB/$PKG -O /tmp/$PKG 2> /dev/null

	if [ -d $PROJECTDIR ]; then
		printf "%s  Removing $PROJECTDIR ...%s\n" "${BLUE}" "${NORMAL}"
		rm -rf $PROJECTDIR
	fi

	printf "%s  Unpacking /tmp/$PKG into $PROJECTDIR ...%s\n" "${BLUE}" "${NORMAL}"
	unzip -qq /tmp/$PKG -d /tmp > /dev/null

	echo "${GREEN}"
	echo "   _____  _____  _____  _____           _____  _____  _____  _____   "
	echo "  |   __||  _  ||  _  ||  |  |   ___   |  |  ||     ||   __||_   _|  "
	echo "  |  |  ||     ||   __||     |  |___|  |     ||  |  ||__   |  | |    "
	echo "  |_____||__|__||__|   |__|__|         |__|__||_____||_____|  |_|    "
	echo "                                                                     "
	echo "  CONFIGURATION SCRIPT (MADE FOR UBUNTU 16.04)${NORMAL}"
	echo
	echo "  [1] ${BOLD}TURN MACHINE INTO A GAPH HOST${NORMAL}"
	echo "  [2] Turn machine into a GAPH-COMPATIBLE host (install programs only)"
	echo "  [3] Apply/upgrade configurations only"
	echo "  [4] Remove configurations (revert configuration files only)"
	echo
	echo "${BLUE}  Hit CTRL+C to exit${NORMAL}"
	echo

	while :;
	do
	  read -p '  #> ' choice
	  case $choice in
		1 ) break ;;
		2 ) break ;;
		3 ) break ;;
		4 ) break ;;
		* )
			tput cuu1
			tput el1
			tput el
			;;
	  esac
	done
}

install_base_software()
{
	echo "  - Instaling base apps"
	if [ ! -f /var/log/gaph/install-base.done ]; then
		if [ ! "$DISPLAY" = "" ]; then
			xterm -e bash -c "initial-software.sh | tee /var/log/gaph/install-base.log"
		else
			bash -c "initial-software.sh | tee /var/log/gaph/install-extra.log"
		fi
	fi
	echo "$(date)" > /var/log/gaph/install-base.done
	echo "    - See installation logs at /var/log/gaph"
}

install_extra_software()
{
	echo "  - Instaling extra apps, ${GREEN}this can take hours, go take a coffe :)${NORMAL} ... "
	# Recover from a possible bronken installation
	if [ ! -f /var/log/gaph/install-extra.done ]; then
		if [ ! "$DISPLAY" = "" ]; then
			xterm -e bash -c "extra-software.sh | tee -a /var/log/gaph/install-base.log"
		else
			bash -c "extra-software.sh | tee -a /var/log/gaph/install-extra.log"
		fi
	fi
	echo "$(date)" > /var/log/gaph/install-extra.done
	echo "    - See installation logs at /var/log/gaph"
}

reboot_host()
{
	echo
	echo "${RED}  HEY YO, SYSTEM WILL REBOOT IN 3 MINUTES! ${NORMAL}"
	echo "  Cancel this with: shutdown -c "
	echo
	shutdown -r +3 2> /dev/null
}

apply_and_upgrade_configs()
{
	echo
	echo "${YELLOW}  Appling/updating configurations ...${NORMAL}"
	install_base_software
	install-scripts.sh -i $PROJECTDIR
	crontab-config.sh -i
	admin-config.sh -i
	config-printers.sh -i
	fstab-config.sh -i
	hosts-config.sh -i
	lightdm-config.sh -i
	nslcd-config.sh -i
	nsswitch-config.sh -i
	saltstack-config.sh -i
	misc-hacks.sh
	users-config.sh
	echo "$(date)" > /var/log/gaph/install-configs.done
}

revert_configurations()
{
	echo
	echo "${YELLOW}  Removing configurations ...${NORMAL}"
	install-scripts.sh -r
	crontab-config.sh -r
	admin-config.sh -r
	config-printers.sh -r
	fstab-config.sh -r
	hosts-config.sh -r
	lightdm-config.sh -r
	nslcd-config.sh -r
	nsswitch-config.sh -r
	saltstack-config.sh -r
	# misc-hacks.sh
	# users-config.sh
	customization.sh -r
	rm -f /var/log/gaph/install-configs.done
}

configure_gaph_host()
{
	echo
	echo "${YELLOW}  Configuring GAPH host ...${NORMAL}"
	install_base_software
	apply_and_upgrade_configs
	install_extra_software
	misc-hacks.sh
	customization.sh -i $PROJECTDIR
	reboot_host
}

configure_gaph_compatible()
{
	echo
	echo "${YELLOW}  Configuring GAPH COMPATIBLE host ...${NORMAL}"
	install_base_software
	install_extra_software
	misc-hacks.sh
	reboot_host
}

clear
echo
main

case $choice in
	1 ) configure_gaph_host ;;
	2 ) configure_gaph_compatible ;;
	3 ) apply_and_upgrade_configs ;;
	4 ) revert_configurations ;;
esac

echo "${YELLOW}  DONE! Bye :) ${NORMAL}"
echo
