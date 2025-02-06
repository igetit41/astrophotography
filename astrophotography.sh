#!/bin/bash

#device_result=$(v4l2-ctl --list-devices | grep -i 'FIBONAX Nova800' -A 1 | grep -i '/dev/video' | xargs)
#resolution=3264x2448
#device_result=$(v4l2-ctl --list-devices | grep -i 'USB 2.0 Camera' -A 1 | grep -i '/dev/video' | xargs)
#resolution=1920x1080

working_dir=/home/d3
echo $working_dir

#gsbucket=$(jq -r '.gsbucket' ./config.json)
pic_timer=$(jq -r '.pic_timer' ./config.json)
file_format=$(jq -r '.file_format' ./config.json)
camera=$(jq -r '.camera' ./config.json)
resolution=$(jq -r '.resolution' ./config.json)

device_result=$(v4l2-ctl --list-devices | grep -i "$camera" -A 1 | grep -i '/dev/video' | xargs)
echo "device_result: $device_result"

if [[ "$device_result" != "" ]]; then
    v4l2-ctl -d /dev/video0 -c auto_exposure=$(jq -r '.auto_exposure' ./config.json)
    v4l2-ctl -d /dev/video0 -c exposure_time_absolute=$(jq -r '.exposure_time_absolute' ./config.json)
    v4l2-ctl -d /dev/video0 -c gain=$(jq -r '.gain' ./config.json)
    v4l2-ctl -d /dev/video0 -c brightness=$(jq -r '.brightness' ./config.json)
    v4l2-ctl -d /dev/video0 -c contrast=$(jq -r '.contrast' ./config.json)

    foldername=$(date +"%Y-%m-%d-%H-%M-%S")
    mkdir -p $working_dir/photos/$foldername
fi

while true; do

    if [[ "$device_result" != "" ]]; then
        # Timestamp
        stamp=$(date +"%Y-%m-%d-%H-%M-%S")

        # Take a pic
        fswebcam -d $device_result -r $resolution --png 9 --no-banner -D 10 --save $working_dir/photos/$foldername/$stamp$file_format
    fi
    
    # Sleep
    sleep $pic_timer
done
