#!/bin/bash

pic_timer=60
fileformat=.jpg

while true; do
    # Timestamp
    stamp=$(date +"%Y-%m-%d-%H-%M-%S")

    # Take a pic
    #fswebcam -r 640x480 --jpeg 85 -D 1 ./photos/$stamp$fileformat
    fswebcam -d /dev/video2 -r 3264x2448 --jpeg 85 -D 1 ./photos/$stamp$fileformat --no-banner

    # Sleep
    sleep $pic_timer
done
