#!/bin/bash
# Update
#sudo apt update -y
#sudo apt-get install fswebcam -y
#sudo apt install v4l-utils -y

#Copy to /home/d3
#sudo chmod +x /home/d3/raspberrypi_startup.sh
#crontab -e
#@reboot  /home/d3/raspberrypi_startup.sh


objective_path=/home/d3

wait_cycles=12
cycle=1
ping -c 1 -q google.com >&/dev/null

while [[ $? != 0 && $cycle < $wait_cycles ]]; do
    sleep 5
    cycle+=1
    ping -c 1 -q google.com >&/dev/null
done

echo "ping: $?"
if [ $? == 0 ]; then
    # Merge changes
    git -C $objective_path/astrophotography restore .
    git -C $objective_path/astrophotography fetch
    git -C $objective_path/astrophotography merge

    # Set up service
    sudo cp $objective_path/astrophotography/astrophotography.service /etc/systemd/system/astrophotography.service

    # Clear out old data
    sudo rm -rfv $objective_path/astrophotography/photos/{*,.*}
fi

# chmod all scripts
sudo chmod +x $objective_path/astrophotography/astrophotography.sh
sudo chmod +x $objective_path/gcloud_auth/gcloud_auth.sh

# Restart Server
sudo systemctl enable astrophotography
sudo systemctl restart astrophotography

#device_result=$(v4l2-ctl --list-devices | grep -i 'USB 2.0 Camera' -A 1 | grep -i '/dev/video' | xargs)
#nohup cvlc -f v4l2://$device_result &

