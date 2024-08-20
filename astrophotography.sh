#!/bin/bash
pic_timer=60
#pic_timer=5
fileformat=.png
path_to_gcloud_auth=../gcloud_auth
gsbucket=sandcastle-401716-photos

device_command="v4l2-ctl --list-devices | grep -i '${1}' -A 1 | grep -i '/dev/video'"
device_resultx=$(v4l2-ctl --list-devices | grep -i \'$1\' -A 1 | grep -i '/dev/video')

device_result=$(v4l2-ctl --list-devices | grep -i 'USB 2.0 Camera' -A 1 | grep -i '/dev/video')
resolution=$2

foldername=$(date +"%Y-%m-%d-%H-%M-%S")
mkdir -p ./photos/$foldername

while true; do
    # Timestamp
    stamp=$(date +"%Y-%m-%d-%H-%M-%S")

    # Take a pic
    fswebcam -d $device_result -r $resolution --png 9 ./photos/$foldername/$stamp$fileformat --no-banner

    # Upload to Cloud Storage
    #gcloud_upload="gcloud storage cp ../astrophotography/photos/$foldername/$stamp$fileformat $gsbucket/$foldername/$stamp$fileformat"
    gcloud_upload="gsutil cp ../astrophotography/photos/$foldername/$stamp$fileformat gs://$gsbucket/$foldername/$stamp$fileformat"
    echo "gcloud_upload: $gcloud_upload"

    # Pass gcloud upload command to gcloud_auth.sh
    upload=$(/bin/bash $path_to_gcloud_auth/gcloud_auth.sh "$gcloud_upload")

    if [[ $upload =~ 'ERROR:' ]]; then
        echo "ERROR: $upload"
    else
        echo "upload: $upload"
        # Remove local copy
        #rm ./photos/$foldername/$stamp$fileformat
    fi
    echo "ARG1: $1"
    echo "device_command: $device_command"
    echo "device_resultx: $device_resultx"
    echo "device_result: $device_result"

    # Sleep
    sleep $pic_timer
done
