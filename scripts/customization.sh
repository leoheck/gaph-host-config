#!/bin/bash

# LightDM Configuration (PRECISA REINICIAR PARA FUNCIONAR)
# Leandro Sehnem Heck (leoheck@gmail.com)

# This script configures the main login screen (LightDM)
# Features:
# - Enable manual login (for network users)
# - Enable the guest login
# - Hide logged users

# Some informations
# https://wiki.ubuntu.com/LightDM
# http://askubuntu.com/questions/155611/no-unity-greeter-conf-file-in-etc-lightdm

key="$1"

install_cmd()
{
	echo "  - Customizing GAPH host"

	SCRIPTDIR=$1

	# PLYMOUNTH BACKUP
	if [ ! -f /lib/plymouth/themes/ubuntu-logo/ubuntu_logo.png.bkp ]; then
		cp /lib/plymouth/themes/ubuntu-logo/ubuntu_logo.png /lib/plymouth/themes/ubuntu-logo/ubuntu_logo.png.bkp
	fi

	sed -i /lib/plymouth/themes/ubuntu-logo/ubuntu_logo.svg
	convert $SCRIPTDIR/images/plymouth/ubuntu_logo.svg /lib/plymouth/themes/ubuntu-logo/ubuntu_logo.png

	# UNITY-GREETER BACKUP
	if [ ! -f /usr/share/unity-greeter/logo.png.bkp ]; then
		cp /usr/share/unity-greeter/logo.png /usr/share/unity-greeter/logo.png.bkp
	fi

	sed -i "s|gaphl00|$(hostname)|g" $SCRIPTDIR/images/unity-greeter/logo.svg
	convert $SCRIPTDIR/images/unity-greeter/logo.svg /usr/share/unity-greeter/logo.png


	# BACKUP
	if [ ! -f /usr/share/glib-2.0/schemas/10_unity_greeter_background.gschema.override ]; then
		cp /usr/share/glib-2.0/schemas/10_unity_greeter_background.gschema.override /usr/share/glib-2.0/schemas/10_unity_greeter_background.gschema.override.bkp
	fi

	# Adiciona o papel de parede do GAPH pra tela de login
	cp $SCRIPTDIR/images/unity-greeter/nigh.png /usr/share/backgrounds/

	#===========================
	read -r -d '' GAPHCONF <<-EOM

	[com.canonical.unity-greeter]
	draw-user-backgrounds=false
	background='/usr/share/backgrounds/night.png'

	EOM
	#===========================

	echo "$GAPHCONF" >> /usr/share/glib-2.0/schemas/10_unity_greeter_background.gschema.override
	glib-compile-schemas /usr/share/glib-2.0/schemas/

}

remove_cmd()
{
	echo "  - Reverting GAPH host customization"

	if [ -f /lib/plymouth/themes/ubuntu-logo/ubuntu_logo.png.bkp ]; then
		mv /lib/plymouth/themes/ubuntu-logo/ubuntu_logo.png.bkp /lib/plymouth/themes/ubuntu-logo/ubuntu_logo.png
	fi

	if [ -f /usr/share/unity-greeter/logo.png.bkp ]; then
		mv /usr/share/unity-greeter/logo.png.bkp /usr/share/unity-greeter/logo.png
	fi

	if [ -f /usr/share/glib-2.0/schemas/10_unity_greeter_background.gschema.override.bkp ]; then
		mv /usr/share/glib-2.0/schemas/10_unity_greeter_background.gschema.override.bkp /usr/share/glib-2.0/schemas/10_unity_greeter_background.gschema.override
	fi
}

case $key in

	-i|--install)
	install_cmd
	exit 0
	;;

	-r|--remove)
	remove_cmd
	exit 0
	;;

	*)
	echo "Unknonw option"
	exit 1

esac