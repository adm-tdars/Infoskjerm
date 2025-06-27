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

# Exit on any error
set -e

echo "Starting Chrome installation and extension setup..."

# Check if Chrome is already installed
if ! command -v google-chrome &> /dev/null; then
    echo "Chrome not found. Installing Chrome..."
    
    # Download and install Chrome
    wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
    echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list
    sudo apt update
    sudo apt install -y google-chrome-stable
    
    echo "Chrome installed successfully!"
else
    echo "Chrome is already installed."
fi

# Extension ID to check and install if missing
EXTENSION_ID="lokonoedfjkdohceegojgcphlolliggd"

# Define Chrome user profile path
CHROME_PROFILE_PATH="$HOME/.config/google-chrome/Default/Preferences"

# Check if the extension is already installed
if [ -f "$CHROME_PROFILE_PATH" ] && grep -q "$EXTENSION_ID" "$CHROME_PROFILE_PATH"; then
    echo "Chrome extension is already installed. Skipping installation."
else
    echo "Setting up Chrome to install extension via policy..."
    
    # Create policy directory if it doesn't exist
    sudo mkdir -p /etc/opt/chrome/policies/managed

    # Create policy file to force install extension
    sudo tee /etc/opt/chrome/policies/managed/extension_policy.json > /dev/null << EOF
{
  "ExtensionInstallForcelist": ["$EXTENSION_ID;https://clients2.google.com/service/update2/crx"]
}
EOF

    echo "Chrome policy set to install extension on next launch."
    
    echo "Starting Chrome with extension installation..."
    google-chrome --no-first-run --password-store=basic "https://chrome.google.com/webstore/detail/$EXTENSION_ID" &
    
    echo "Done! Chrome should be running and attempting to install your extension."
    echo "You may need to confirm the installation in Chrome's interface."
fi

# Start Chrome normally without keyring prompts
echo "Launching Chrome..."
google-chrome --no-first-run --password-store=basic &

echo "Script finished."
