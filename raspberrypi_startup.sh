#!/bin/bash
# Setup
#sudo apt update -y
#sudo apt-get update -y
#sudo apt-get install fswebcam -y
#sudo apt install v4l-utils -y
#sudo apt-get install jq -y
#
#sudo apt-get install apt-transport-https ca-certificates gnupg curl -y
#curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
#echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
#sudo apt-get update -y && sudo apt-get install google-cloud-cli -y
#echo 'export PATH="$PATH:/usr/lib/google-cloud-sdk/bin"' >> ~/.bashrc
#
#git -C /home/d3 clone https://github.com/igetit41/astrophotography.git
#git config --global --add safe.directory /home/d3/astrophotography
#cp -R /home/d3/astrophotography/gcloud_auth /home/d3/
#cp /home/d3/astrophotography/raspberrypi_startup.sh /home/d3/
#sudo chmod +x /home/d3/raspberrypi_startup.sh
#sudo chmod +x /home/d3/gcloud_auth/gcloud_auth.sh
#pico /home/d3/sa_key.json
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

    cp -R $objective_path/astrophotography/gcloud_auth $objective_path/

    # chmod all scripts
    sudo chmod +x $objective_path/astrophotography/astrophotography.sh
    sudo chmod +x $objective_path/astrophotography/image_upload.sh
    sudo chmod +x $objective_path/gcloud_auth/gcloud_auth.sh

    # Set up service
    sudo cp $objective_path/astrophotography/astrophotography.service /etc/systemd/system/astrophotography.service
    sudo cp $objective_path/astrophotography/image_upload.service /etc/systemd/system/image_upload.service

    # Clear out old data
    #sudo rm -rfv $objective_path/photos/{*,.*}

    # Restart Servers
    sudo systemctl enable astrophotography
    sudo systemctl restart astrophotography
    sudo systemctl enable image_upload
    sudo systemctl restart image_upload
fi

#device_result=$(v4l2-ctl --list-devices | grep -i 'USB 2.0 Camera' -A 1 | grep -i '/dev/video' | xargs)
#nohup cvlc -f v4l2://$device_result &

