#!/bin/bash
#pic_timer=60
pic_timer=5
fileformat=.png
path_to_gcloud_auth=../gcloud_auth
gsbucke=gs://sandcastle-401716-photos
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
    gcloud_upload="gcloud storage cp ../astrophotography/photos/$foldername/$stamp$fileformat $gsbucket/$foldername/$stamp$fileformat"
    echo "gcloud_upload: $gcloud_upload"

    # Pass gcloud upload command to gcloud_auth.sh
    upload=$(/bin/bash $path_to_gcloud_auth/gcloud_auth.sh "$gcloud_upload")

    if [[ $upload =~ 'ERROR:' ]]; then
        echo "ERROR: $upload"
    else
        echo "upload: $upload"
        # Remove local copy
        rm ./photos/$foldername/$stamp$fileformat
    fi

    # Sleep
    sleep $pic_timer
done
