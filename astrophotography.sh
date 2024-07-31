#!/bin/bash
pic_timer=60
#fileformat=.jpg
fileformat=.png
device=$(v4l2-ctl --list-devices | grep -i 'FIBONAX Nova800' -A 1 | grep -i '/dev/video')
foldername=$(date +"%Y-%m-%d-%H-%M-%S")
mkdir -p ./photos/$foldername

while true; do
    # Timestamp
    stamp=$(date +"%Y-%m-%d-%H-%M-%S")

    # Take a pic
    #fswebcam -d $device -r 3264x2448 --jpeg 95 -D 1 $folderpath$stamp$fileformat --no-banner
    fswebcam -d $device -r 3264x2448 --png 9 ./photos/$foldername/$stamp$fileformat --no-banner

    # Upload to Cloud Storage
    echo "gcloud storage cp ./photos/$foldername/$stamp$fileformat gs://$gcp_project/$foldername/$stamp$fileformat"
    upload=$(gcloud storage cp ./photos/$foldername/$stamp$fileformat gs://$gcp_project/$foldername/$stamp$fileformat)

    # Sleep
    sleep $pic_timer
done
