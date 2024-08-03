#!/bin/bash
# Update
#sudo apt update -y
#sudo apt-get install fswebcam -y
#sudo apt install v4l-utils -y

git -C ~/astrophotography restore .
git -C ~/astrophotography fetch
git -C ~/astrophotography merge

sudo rm -rfv /home/d3/astrophotography/photos/{*,.*}
sudo chmod +x /home/d3/astrophotography/astrophotography.sh
sudo cp /home/d3/astrophotography/astrophotography.service /etc/systemd/system/astrophotography.service

# Restart Server
sudo systemctl enable astrophotography
sudo systemctl restart astrophotography
