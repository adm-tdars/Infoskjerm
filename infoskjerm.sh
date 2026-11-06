#!/bin/bash

set -e

KIOSK_USER="infoskjerm"
KIOSK_HOME="/home/$KIOSK_USER"
KIOSK_URL="https://infoskjerm.ssnit.no/screen"
KIOSK_PROFILE="$KIOSK_HOME/.config/google-chrome-kiosk"

echo "=========================================="
echo " Setter opp SSN Infoskjerm"
echo "=========================================="

# --------------------------------------------------
# 1. Remove Chromium if installed
# --------------------------------------------------

echo "Fjerner eventuell Chromium-installasjon..."

sudo apt remove --purge -y chromium-browser chromium 2>/dev/null || true
sudo apt autoremove -y


# --------------------------------------------------
# 2. Remove old kiosk configuration
# --------------------------------------------------

echo "Fjerner gammelt kiosk-oppsett..."

sudo rm -f "$KIOSK_HOME/kiosk.sh"
sudo rm -f /etc/xdg/autostart/kiosk.desktop
sudo rm -f "$KIOSK_HOME/.config/autostart/kiosk.desktop"

# Remove old extension policy
sudo rm -f /etc/opt/chrome/policies/managed/extension_policy.json


# --------------------------------------------------
# 3. Install Google Chrome if missing
# --------------------------------------------------

if ! command -v google-chrome >/dev/null 2>&1; then

    echo "Google Chrome er ikke installert. Installerer..."

    wget -q -O /tmp/google-chrome.deb \
        https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb

    sudo apt install -y /tmp/google-chrome.deb

    rm -f /tmp/google-chrome.deb

    echo "Google Chrome installert."

else
    echo "Google Chrome er allerede installert."
fi


# --------------------------------------------------
# 4. Create dedicated kiosk profile
# --------------------------------------------------

echo "Oppretter egen Chrome-profil for infoskjerm..."

sudo mkdir -p "$KIOSK_PROFILE"
sudo chown -R "$KIOSK_USER:$KIOSK_USER" "$KIOSK_PROFILE"


# --------------------------------------------------
# 5. Create kiosk startup script
# --------------------------------------------------

echo "Oppretter kiosk.sh..."

sudo tee "$KIOSK_HOME/kiosk.sh" >/dev/null <<EOF
#!/bin/bash

KIOSK_URL="$KIOSK_URL"
KIOSK_PROFILE="$KIOSK_PROFILE"

# Wait for desktop to finish starting
sleep 8

# Disable screen blanking
xset s off 2>/dev/null || true
xset s noblank 2>/dev/null || true
xset -dpms 2>/dev/null || true

# Close any Chrome processes already running
pkill -f google-chrome 2>/dev/null || true
pkill -f chrome 2>/dev/null || true

sleep 2

# Make sure kiosk profile directory exists
mkdir -p "\$KIOSK_PROFILE"

# Start Chrome in real kiosk mode
exec /usr/bin/google-chrome \
    --kiosk \
    --start-fullscreen \
    --no-first-run \
    --no-default-browser-check \
    --disable-session-crashed-bubble \
    --disable-infobars \
    --disable-translate \
    --disable-features=Translate \
    --password-store=basic \
    --user-data-dir="\$KIOSK_PROFILE" \
    "\$KIOSK_URL"
EOF

sudo chmod +x "$KIOSK_HOME/kiosk.sh"
sudo chown "$KIOSK_USER:$KIOSK_USER" "$KIOSK_HOME/kiosk.sh"


# --------------------------------------------------
# 6. Create autostart
# --------------------------------------------------

echo "Oppretter autostart..."

sudo mkdir -p "$KIOSK_HOME/.config/autostart"

sudo tee "$KIOSK_HOME/.config/autostart/kiosk.desktop" >/dev/null <<EOF
[Desktop Entry]
Type=Application
Name=SSN Infoskjerm Kiosk
Comment=Starter SSN Infoskjerm
Exec=$KIOSK_HOME/kiosk.sh
Terminal=false
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
StartupNotify=false
EOF

sudo chown -R "$KIOSK_USER:$KIOSK_USER" "$KIOSK_HOME/.config"


# --------------------------------------------------
# 7. Disable Chrome normal autostart if present
# --------------------------------------------------

echo "Sjekker etter andre Chrome autostart-filer..."

find "$KIOSK_HOME/.config/autostart" \
    -type f \
    -iname "*chrome*" \
    ! -name "kiosk.desktop" \
    -delete 2>/dev/null || true


# --------------------------------------------------
# Finished
# --------------------------------------------------

echo ""
echo "=========================================="
echo " FERDIG!"
echo "=========================================="
echo ""
echo "Chrome skal nå starte:"
echo ""
echo "  $KIOSK_URL"
echo ""
echo "i full kiosk-modus."
echo ""
echo "Kiosk-script:"
echo "  $KIOSK_HOME/kiosk.sh"
echo ""
echo "Autostart:"
echo "  $KIOSK_HOME/.config/autostart/kiosk.desktop"
echo ""
echo "Restart maskinen med:"
echo ""
echo "  sudo reboot"
echo ""
