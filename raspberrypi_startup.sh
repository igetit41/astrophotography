#!/bin/bash
# Update
sudo apt update -y
sudo apt-get install fswebcam -y

git -C ~/astrophotography fetch
git -C ~/astrophotography merge

sudo chmod +x ~/astrophotography/astrophotography.sh
sudo cp ~/astrophotography/astrophotography.service /etc/systemd/system/astrophotography.service

# Restart Server
sudo systemctl enable astrophotography
sudo systemctl restart astrophotography
