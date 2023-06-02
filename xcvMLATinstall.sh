#!/bin/bash
# Bratwurst xcv-mlat Setup
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
if ( ! whiptail --title "XCV-MLAT SETUP" --defaultno --yesno "This will install the XCV-MLAT Setup. Continue?" 10 58 ); then
  exit
fi

######################################
# Check if adsbexchange is installed #
######################################
if [ -x /usr/local/share/adsbexchange/venv/bin/mlat-client ]; then
  echo -e "\e[36m=>\e[0m Installation started ..."
else
  whiptail --title "Error" --msgbox "adsbexchange-mlat files not found." 8 40
  if ( whiptail --title "MLAT" --yesno "Do you want to install MLAT (Multilateration / Quadriangulation)? (strongly recommended)\n\nSimply explained: Not every aircraft sends clean ADS-B with location data, and to capture these aircraft with location data anyway MLAT is used.\n\nIn this case, the MLAT service from ADSBexchange.com is used." 15 58 ); then
    echo -e "\e[36m=>\e[0m Installing ADSBexchange MLAT."
    whiptail --msgbox --nocancel "Notes:\n\n1. A station name has to be specified in the following setup to use MLAT. Please report this name to RundesBalli.\n\n2. The same coordinates must be entered as in the first input.\n\n3. Find your Sea Level here:\nhttps://www.mapcoordinates.net/en\nAdd the height of your antenna (from the ground) to this height." 19 58
    bash -c "$(curl -L -o - https://adsbexchange.com/feed.sh)"
    echo -e "\e[36m=>\e[0m Setting up privacy mode."
    sed --follow-symlinks -i -e 's/PRIVACY=.*/PRIVACY="--privacy"/' /etc/default/adsbexchange
    echo -e "\e[36m=>\e[0m Setting up MLAT forwarding to bratwurst."
    sed --follow-symlinks -i -e 's/RESULTS=.*/RESULTS="--results beast,connect,127.0.0.1:30104"/' /etc/default/adsbexchange
    echo -e "\e[36m=>\e[0m MLAT installation complete."
  else
    echo -e "\e[36m=>\e[0m Not installing ADSBexchange MLAT."
	exit
  fi
fi

################
# Installation #
################
echo
echo -e "\e[36m----------------------------------------\e[0m"
echo
echo -e "\e[36m             Installation\e[0m"
echo
echo -e "\e[36m----------------------------------------\e[0m"
echo

echo -e "\e[36m=>\e[0m Install files ..."
tee /usr/local/share/adsbexchange/xcv-mlat.sh >/dev/null << EOF
#!/bin/bash
source /etc/default/xcv-mlat

if [[ "\$LATITUDE" == 0 ]] || [[ "\$LONGITUDE" == 0 ]] || [[ "\$USER" == 0 ]] || [[ "\$USER" == "disable" ]]; then
    echo MLAT DISABLED
    sleep 3600
    exit
fi

INPUT_IP=\$(echo \$INPUT | cut -d: -f1)
INPUT_PORT=\$(echo \$INPUT | cut -d: -f2)

sleep 2

while ! nc -z "\$INPUT_IP" "\$INPUT_PORT" && command -v nc &>/dev/null; do
    echo "Could not connect to \$INPUT_IP:\$INPUT_PORT, retry in 10 seconds."
    sleep 10
done

exec /usr/local/share/adsbexchange/venv/bin/mlat-client \\
    --input-type "\$INPUT_TYPE" --no-udp \\
    --input-connect "\$INPUT" \\
    --server "\$MLATSERVER" \\
    --user "\$USER" \\
    --lat "\$LATITUDE" \\
    --lon "\$LONGITUDE" \\
    --alt "\$ALTITUDE" \\
    \$PRIVACY \\
    \$UUID_FILE \\
    \$RESULTS \$RESULTS1 \$RESULTS2 \$RESULTS3 \$RESULTS4

EOF

echo -e "\e[36m=>\e[0m Install service ..."
tee /lib/systemd/system/xcv-mlat.service >/dev/null << EOF
[Unit]
Description=xcv-mlat
Wants=network.target
After=network.target

[Service]
User=adsbexchange
ExecStart=/usr/local/share/adsbexchange/xcv-mlat.sh
Type=simple
Restart=always
RestartSec=30
StartLimitInterval=1
StartLimitBurst=100
SyslogIdentifier=xcv-mlat
Nice=-1

[Install]
WantedBy=default.target

EOF

echo -e "\e[92mInstallation complete.\e[0m"

#################
# Configuration #
#################
echo
echo -e "\e[36m----------------------------------------\e[0m"
echo
echo -e "\e[36m            Configuration\e[0m"
echo
echo -e "\e[36m----------------------------------------\e[0m"
echo

sudo cp /etc/default/adsbexchange /etc/default/xcv-mlat

echo -e "\e[36m=>\e[0m Removing not needed parameters ..."
sudo sed --follow-symlinks -i -e '/^RESULTS[2-4]=.*/d' /etc/default/xcv-mlat
sudo sed --follow-symlinks -i -e '/^TARGET=.*/d' /etc/default/xcv-mlat
sudo sed --follow-symlinks -i -e '/^NET_OPTIONS=.*/d' /etc/default/xcv-mlat
sudo sed --follow-symlinks -i -e '/^JSON_OPTIONS=.*/d' /etc/default/xcv-mlat

echo -e "\e[36m=>\e[0m Setting server and port ..."
sudo sed --follow-symlinks -i -e 's/^MLATSERVER=.*/MLATSERVER="xcv.vc:3000"/g' /etc/default/xcv-mlat

echo -e "\e[Configuration done.\e[0m"

######################
# Service enablement #
######################
echo
echo -e "\e[36m----------------------------------------\e[0m"
echo
echo -e "\e[36m            Enable Service\e[0m"
echo
echo -e "\e[36m----------------------------------------\e[0m"
echo

sudo chmod +x /usr/local/share/adsbexchange/xcv-mlat.sh
sudo systemctl start xcv-mlat.service && systemctl enable xcv-mlat.service

echo -e "\e[92mService started.\e[0m"

##########
# Finish #
##########
echo
echo -e "\e[36m----------------------------------------\e[0m"
echo
echo -e "\e[92m               Finished\e[0m"
echo
echo -e "\e[36m          Sync statistic site:\e[0m"
echo -e "\e[36m          http://www.xcv.vc/sync/\e[0m"
echo
echo -e "\e[36m----------------------------------------\e[0m"
echo

exit
