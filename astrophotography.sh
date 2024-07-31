#!/bin/bash

pic_timer=300
fileformat=.jpg

while [true]
do
    # Timestamp
    stamp=$(date +"%Y-%m-%d-%H-%M-%S")
    name=$stamp$fileformat

    # Take a pic
    fswebcam -r 640x480 --jpeg 85 -D 1 ./photos/$name

    # Sleep
    sleep $pic_timer
done
