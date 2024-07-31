#!/bin/bash
pic_timer=60
fileformat=.jpg
device=$(v4l2-ctl --list-devices | grep -i 'FIBONAX Nova800' -A 1 | grep -i '/dev/video')

while true; do
    # Timestamp
    stamp=$(date +"%Y-%m-%d-%H-%M-%S")

    # Take a pic
    fswebcam -d $device -r 3264x2448 --jpeg 85 -D 1 ./photos/$stamp$fileformat --no-banner

    # Sleep
    sleep $pic_timer
done
