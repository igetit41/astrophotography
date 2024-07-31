#!/bin/bash

pic_timer=300
fileformat=.jpg

#while [true]
#do
    # Timestamp
    stamp=$(date +"%Y-%m-%d-%H-%M-%S")
    name=$stamp$fileformat

    # Take a pic
    #fswebcam -r 640x480 --jpeg 85 -D 1 ./photos/$name
    fswebcam -d /dev/video2 -r 3264x2448 --jpeg 85 -D 1 ./photos/$name --no-banner

    # Sleep
    sleep $pic_timer
#done
