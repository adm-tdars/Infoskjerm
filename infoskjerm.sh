#!/bin/bash
set -e

KIOSK_USER="infoskjerm"
KIOSK_HOME="/home/$KIOSK_USER"
KIOSK_URL="https://infoskjerm.ssnit.no/screen"

echo "=========================================="
echo " SSN INFOSKJERM - KIOSK SETUP"
echo "=========================================="

# Sjekk at brukeren finnes
if ! id "$KIOSK_USER" >/dev/null 2>&1; then
    echo "FEIL: Brukeren $KIOSK_USER finnes ikke."
    exit 1
fi

# Finn Chrome
CHROME_BIN="$(command -v google-chrome || true)"

if [ -z "$CHROME_BIN" ]; then
    echo "Google Chrome mangler. Installerer..."

    wget -q -O /tmp/google-chrome.deb \
        https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb

    sudo apt update
    sudo apt install -y /tmp/google-chrome.deb
    rm -f /tmp/google-chrome.deb

    CHROME_BIN="$(command -v google-chrome)"
fi

echo "Chrome: $CHROME_BIN"

# --------------------------------------------------
# Fjern gammelt kiosk-oppsett
# --------------------------------------------------

echo "Rydder gammelt kiosk-oppsett..."

sudo rm -f "$KIOSK_HOME/kiosk.sh"
sudo rm -f "$KIOSK_HOME/.config/autostart/kiosk.desktop"
sudo rm -f /etc/xdg/autostart/kiosk.desktop

# Sørg for at autostart-mappen finnes
sudo -u "$KIOSK_USER" mkdir -p "$KIOSK_HOME/.config/autostart"

# --------------------------------------------------
# Opprett kiosk/watchdog-script
# --------------------------------------------------

echo "Oppretter kiosk-script..."

sudo tee "$KIOSK_HOME/kiosk.sh" >/dev/null <<EOF
#!/bin/bash

URL="$KIOSK_URL"
CHROME="$CHROME_BIN"

# Vent litt på at skrivebordet/nettverket kommer opp
sleep 5

while true
do
    echo "Starter SSN Infoskjerm..."

    "\$CHROME" \
        --kiosk "\$URL" \
        --no-first-run \
        --no-default-browser-check \
        --disable-session-crashed-bubble \
        --disable-infobars \
        --disable-features=Translate \
        --password-store=basic \
        --start-fullscreen

    echo "Chrome ble lukket eller krasjet."
    echo "Starter igjen om 2 sekunder..."

    sleep 2
done
EOF

sudo chmod +x "$KIOSK_HOME/kiosk.sh"
sudo chown "$KIOSK_USER:$KIOSK_USER" "$KIOSK_HOME/kiosk.sh"

# --------------------------------------------------
# Autostart ved innlogging
# --------------------------------------------------

echo "Setter opp autostart..."

sudo tee "$KIOSK_HOME/.config/autostart/kiosk.desktop" >/dev/null <<EOF
[Desktop Entry]
Type=Application
Name=SSN Infoskjerm
Comment=Starter SSN infoskjerm i kioskmodus
Exec=$KIOSK_HOME/kiosk.sh
Terminal=false
X-GNOME-Autostart-enabled=true
Hidden=false
NoDisplay=false
EOF

sudo chown "$KIOSK_USER:$KIOSK_USER" \
    "$KIOSK_HOME/.config/autostart/kiosk.desktop"

# --------------------------------------------------
# Deaktiver Chrome session restore prompt
# --------------------------------------------------

sudo mkdir -p /etc/opt/chrome/policies/managed

sudo tee /etc/opt/chrome/policies/managed/ssn-kiosk.json >/dev/null <<EOF
{
    "RestoreOnStartup": 4,
    "RestoreOnStartupURLs": [
        "$KIOSK_URL"
    ],
    "DefaultBrowserSettingEnabled": false
}
EOF

chmod 644 /etc/opt/chrome/policies/managed/ssn-kiosk.json

echo ""
echo "=========================================="
echo " FERDIG!"
echo "=========================================="
echo ""
echo "Bruker: $KIOSK_USER"
echo "URL:    $KIOSK_URL"
echo ""
echo "Chrome starter automatisk ved innlogging."
echo "Chrome starter i kiosk/fullskjerm."
echo "Lukkes Chrome -> starter den igjen."
echo "Krasjer Chrome -> starter den igjen."
echo ""
echo "Restart maskinen for aa teste:"
echo ""
echo "sudo reboot"
echo ""
