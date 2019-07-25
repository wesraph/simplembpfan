#!/bin/sh
set -e

echo "Installing on /usr/sbin/simplembpfan"
sudo cp fan.sh /usr/sbin/simplembpfan -fv

if [ -d /etc/systemd/system/ ]; then
    dialog --title "Systemd unit" \
    --backtitle "Installation" \
    --yesno "Do you want to install the systemd unit ?" 7 60

    response=$?
    if [ "$response" ]; then
        sudo cp simplembpfan.service /etc/systemd/system/simplembpfan.service -fv
        sudo systemctl daemon-reload
    fi

    dialog --title "Systemd unit" \
    --backtitle "Installation" \
    --yesno "Do you want to run it at boot time ?" 7 60
    response=$?

    if [ "$response" ]; then
        sudo systemctl enable simplembpfan
    fi
fi



