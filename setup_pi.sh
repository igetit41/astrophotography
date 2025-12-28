#!/bin/bash
# Complete Raspberry Pi setup script for astrophotography workload
# Run this once after fresh Raspberry Pi OS installation

set -e  # Exit on any error

echo "========================================="
echo "Astrophotography Raspberry Pi Setup"
echo "========================================="

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo "Please run this script as a regular user (not root/sudo)"
   echo "The script will prompt for sudo when needed"
   exit 1
fi

# Get current user info
CURRENT_USER=$(whoami)
USER_HOME="/home/$CURRENT_USER"
echo "Setting up for user: $CURRENT_USER"
echo "Home directory: $USER_HOME"

# Function to check if command succeeded
check_status() {
    if [ $? -eq 0 ]; then
        echo "SUCCESS: $1 completed successfully"
    else
        echo "ERROR: $1 failed"
        exit 1
    fi
}

echo ""
echo "Step 1: Updating system packages..."
sudo apt update -y
sudo apt-get update -y
check_status "System update"

echo ""
echo "Step 2: Installing camera and utility dependencies..."
sudo apt-get install -y fswebcam v4l-utils jq imagemagick bc git
check_status "Camera dependencies installation"

echo ""
echo "Step 3: Installing Google Cloud CLI..."
sudo apt-get install -y apt-transport-https ca-certificates gnupg curl
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
sudo apt-get update -y && sudo apt-get install -y google-cloud-cli
echo 'export PATH="$PATH:/usr/lib/google-cloud-sdk/bin"' >> ~/.bashrc
check_status "Google Cloud CLI installation"

echo ""
echo "Step 4: Cloning astrophotography repository..."
if [ -d "$USER_HOME/astrophotography" ]; then
    echo "Repository already exists, updating..."
    git -C $USER_HOME/astrophotography pull
else
    git -C $USER_HOME clone https://github.com/igetit41/astrophotography.git
fi
git config --global --add safe.directory $USER_HOME/astrophotography
check_status "Repository setup"

echo ""
echo "Step 5: Setting up project files..."
cp -R $USER_HOME/astrophotography/gcloud_auth $USER_HOME/
cp $USER_HOME/astrophotography/raspberrypi_startup.sh $USER_HOME/
sudo chmod +x $USER_HOME/raspberrypi_startup.sh
sudo chmod +x $USER_HOME/astrophotography/astrophotography.sh
sudo chmod +x $USER_HOME/astrophotography/image_upload.sh
sudo chmod +x $USER_HOME/gcloud_auth/gcloud_auth.sh
check_status "Project files setup"

echo ""
echo "Step 6: Configuring SSH access..."
sudo systemctl enable ssh
sudo systemctl start ssh
check_status "SSH configuration"

echo ""
echo "Step 7: Network configuration..."
read -p "Enter your WiFi network name (SSID) for static IP setup: " WIFI_SSID
read -p "Enter desired static IP (e.g., 192.168.1.100): " STATIC_IP
read -p "Enter your router IP (e.g., 192.168.1.1): " ROUTER_IP

# Extract network prefix from static IP (e.g., 192.168.1.100 -> 192.168.1)
NETWORK_PREFIX=$(echo $STATIC_IP | cut -d'.' -f1-3)

# Update the startup script with actual network values
sed -i "s/YOUR_WIFI_NAME/$WIFI_SSID/g" $USER_HOME/raspberrypi_startup.sh
sed -i "s/192.168.1.100/$STATIC_IP/g" $USER_HOME/raspberrypi_startup.sh
sed -i "s/192.168.1.1/$ROUTER_IP/g" $USER_HOME/raspberrypi_startup.sh

check_status "Network configuration"

echo ""
echo "Step 8: Setting up Google Cloud service account..."
echo "You need to create a service account key file."
echo "Please paste the entire JSON content of your service account key below."
echo "After pasting, press Ctrl+D on a new line to finish:"
echo ""

cat > $USER_HOME/sa_key.json
chmod 600 $USER_HOME/sa_key.json
check_status "Service account key setup"

echo ""
echo "Step 9: Setting up automatic startup..."
# Add crontab entry if it doesn't exist
if ! crontab -l 2>/dev/null | grep -q "raspberrypi_startup.sh"; then
    (crontab -l 2>/dev/null; echo "@reboot $USER_HOME/raspberrypi_startup.sh") | crontab -
    check_status "Crontab setup"
else
    echo "SUCCESS: Crontab entry already exists"
fi

echo ""
echo "Step 10: Testing camera detection..."
if v4l2-ctl --list-devices | grep -i camera > /dev/null; then
    echo "SUCCESS: Camera detected"
    v4l2-ctl --list-devices
else
    echo "WARNING: No camera detected - please connect camera and reboot"
fi

echo ""
echo "Step 11: Testing internet connectivity..."
if ping -c 1 -q google.com >&/dev/null; then
    echo "SUCCESS: Internet connectivity confirmed"
else
    echo "WARNING: No internet connectivity - please check WiFi configuration"
fi

echo ""
echo "========================================="
echo "Setup Complete!"
echo "========================================="
echo ""
echo "Summary:"
echo "- User: $CURRENT_USER"
echo "- SSH access: ssh $CURRENT_USER@$STATIC_IP (after reboot)"
echo "- Project directory: $USER_HOME/astrophotography"
echo "- Active profile: $(jq -r '.active_profile' $USER_HOME/astrophotography/config.json)"
echo ""
echo "Next steps:"
echo "1. Reboot the Raspberry Pi: sudo reboot"
echo "2. After reboot, the system will:"
echo "   - Apply static IP configuration"
echo "   - Start astrophotography services automatically"
echo "   - Begin capturing based on profile settings"
echo ""
echo "To change photography profiles, edit:"
echo "$USER_HOME/astrophotography/config.json"
echo ""
echo "To monitor the system:"
echo "ssh $CURRENT_USER@$STATIC_IP"
echo "sudo systemctl status astrophotography"
echo "sudo systemctl status image_upload"
echo ""
echo "Setup completed successfully!"
