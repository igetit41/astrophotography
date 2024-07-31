#!/bin/bash

pic_timer=300
fileformat=.png

while [true]
do
    # Timestamp
    stamp=$(date +"%Y-%m-%d-%H-%M-%S")
    name=$stamp$fileformat

    # Take a pic
    #fswebcam -r 640x480 --jpeg 85 -D 1 ./photos/$name
    fswebcam -d /dev/video2 -r 640x480 --png 10 -D 1 ./photos/$name --no-banner

    # Sleep
    sleep $pic_timer
done
