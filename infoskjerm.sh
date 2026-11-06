#!/bin/bash

set -e

KIOSK_USER="infoskjerm"
KIOSK_URL="https://infoskjerm.ssnit.no/screen"

echo "Setter opp Chrome kiosk..."

# --------------------------------------------------
# 1. Remove Chromium if installed
# --------------------------------------------------
echo "Fjerner eventuell Chromium-installasjon..."

sudo apt remove --purge -y chromium-browser chromium 2>/dev/null || true
sudo apt autoremove -y


# --------------------------------------------------
# 2. Remove old kiosk configuration
# --------------------------------------------------
if [ -f /home/$KIOSK_USER/kiosk.sh ]; then
    sudo rm -f /home/$KIOSK_USER/kiosk.sh
    echo "Fjernet gammel kiosk.sh"
fi

if [ -f /etc/xdg/autostart/kiosk.desktop ]; then
    sudo rm -f /etc/xdg/autostart/kiosk.desktop
    echo "Fjernet gammel kiosk.desktop"
fi


# --------------------------------------------------
# 3. Remove old Chrome extension policy
# --------------------------------------------------
if [ -f /etc/opt/chrome/policies/managed/extension_policy.json ]; then
    sudo rm -f /etc/opt/chrome/policies/managed/extension_policy.json
    echo "Fjernet gammel Chrome extension-policy"
fi


# --------------------------------------------------
# 4. Remove old kiosk cronjob
# --------------------------------------------------
sudo crontab -l 2>/dev/null | grep -v "killall chrome" | sudo crontab - 2>/dev/null || true


# --------------------------------------------------
# 5. Install Google Chrome if missing
# --------------------------------------------------
if ! command -v google-chrome >/dev/null 2>&1; then

    echo "Chrome er ikke installert. Installerer..."

    wget -q -O /tmp/google-chrome-stable_current_amd64.deb \
        https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb

    sudo apt install -y /tmp/google-chrome-stable_current_amd64.deb

    rm -f /tmp/google-chrome-stable_current_amd64.deb

    echo "Chrome installert."

else
    echo "Chrome er allerede installert."
fi


# --------------------------------------------------
# 6. Create kiosk startup script
# --------------------------------------------------
echo "Oppretter kiosk-script..."

sudo tee /home/$KIOSK_USER/kiosk.sh >/dev/null <<EOF
#!/bin/bash

sleep 5

# Disable screen blanking / power saving
xset s off
xset -dpms
xset s noblank

# Remove possible Chrome crash warning
sed -i 's/"exit_type":"Crashed"/"exit_type":"Normal"/' \
    /home/$KIOSK_USER/.config/google-chrome/Default/Preferences 2>/dev/null || true

# Start Chrome in kiosk mode
exec google-chrome \
    --kiosk \
    --no-first-run \
    --no-default-browser-check \
    --password-store=basic \
    --disable-session-crashed-bubble \
    --disable-infobars \
    "$KIOSK_URL"
EOF

sudo chmod +x /home/$KIOSK_USER/kiosk.sh
sudo chown $KIOSK_USER:$KIOSK_USER /home/$KIOSK_USER/kiosk.sh


# --------------------------------------------------
# 7. Create autostart entry for kiosk user
# --------------------------------------------------
echo "Setter opp automatisk oppstart..."

sudo mkdir -p /home/$KIOSK_USER/.config/autostart

sudo tee /home/$KIOSK_USER/.config/autostart/kiosk.desktop >/dev/null <<EOF
[Desktop Entry]
Type=Application
Name=SSN Infoskjerm
Comment=Starter SSN infoskjerm i Chrome kiosk mode
Exec=/home/$KIOSK_USER/kiosk.sh
Terminal=false
X-GNOME-Autostart-enabled=true
EOF

sudo chown -R $KIOSK_USER:$KIOSK_USER /home/$KIOSK_USER/.config/autostart


# --------------------------------------------------
# Finished
# --------------------------------------------------
echo ""
echo "=========================================="
echo " SSN Infoskjerm er konfigurert"
echo "=========================================="
echo ""
echo "URL: $KIOSK_URL"
echo "Modus: Chrome Kiosk"
echo "Bruker: $KIOSK_USER"
echo ""
echo "Start maskinen på nytt for å teste:"
echo ""
echo "sudo reboot"
echo ""
