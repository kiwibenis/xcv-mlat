#!/bin/bash
# Bratwurst xcv-mlat uninstaller
# v0.1
clear

##############
# Root check #
##############
if [ $(/usr/bin/id -u) -ne 0 ]; then
    whiptail --title "Error" --msgbox "You have to run this script as a root user!" 8 40
    exit
fi

############
# Question #
############
if (! whiptail --title "XCV-MLAT SETUP" --defaultno --yesno "This will uninstall the XCV-MLAT Setup. Continue?" 10 58); then
    exit
fi

#######################
# Disable  and Remove #
#######################
sudo systemctl stop xcv-mlat.service && systemctl disable xcv-mlat.service
sudo rm /etc/default/xcv-mlat
sudo rm /lib/systemd/system/xcv-mlat.service
sudo rm /usr/local/share/adsbexchange/xcv-mlat.sh

##########
# Finish #
##########
clear
echo
echo -e "\e[36m----------------------------------------\e[0m"
echo
echo -e "\e[92m          Removed xcv-MLAT\e[0m"
echo
echo -e "\e[36m----------------------------------------\e[0m"
echo

exit
