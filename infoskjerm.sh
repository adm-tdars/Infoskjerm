#!/bin/bash

# Remove Chromium browser
sudo apt remove --purge -y chromium-browser
sudo apt autoremove -y

# Remove the kiosk script if it exists
if [ -f /home/infoskjerm/kiosk.sh ]; then
    sudo rm /home/infoskjerm/kiosk.sh
    echo "Removed /home/infoskjerm/kiosk.sh"
fi

# Remove the autostart desktop entry
if [ -f /etc/xdg/autostart/kiosk.desktop ]; then
    sudo rm /etc/xdg/autostart/kiosk.desktop
    echo "Removed /etc/xdg/autostart/kiosk.desktop"
fi

# Remove the specific cronjob
sudo crontab -l | grep -v "killall chrome" | sudo crontab -
echo "Removed kiosk-related cron job from root crontab"
