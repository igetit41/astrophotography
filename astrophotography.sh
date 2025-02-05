#!/bin/bash
pic_timer=60
#pic_timer=5
fileformat=.png
path_to_gcloud_auth=../gcloud_auth
gsbucket=sandcastle-401716-photos

#device="'${1}'"
#device_resultx=$(v4l2-ctl --list-devices | grep -i $device -A 1 | grep -i '/dev/video' | xargs)

#resolution=$2
#device_result=$(v4l2-ctl --list-devices | grep -i 'FIBONAX Nova800' -A 1 | grep -i '/dev/video' | xargs)
#resolution=3264x2448

camera=$(jq -r '.camera' ./config.json)
resolution=$(jq -r '.resolution' ./config.json)

device_result=$(v4l2-ctl --list-devices | grep -i $camera -A 1 | grep -i '/dev/video' | xargs)
#resolution=1920x1080

#auto_exposure_result=$(v4l2-ctl -d $device_result --set-ctrl auto_exposure=3)
#set_controls_result=$(v4l2-ctl -d $device_result -c auto_exposure=1 -c exposure_time_absolute=5000 -c brightness=30 -c gain=50 -c contrast=32)

#cvlc_result=$(nohup cvlc -f v4l2://$device_result &)

v4l2-ctl -d /dev/video0 -c auto_exposure=$(jq -r '.auto_exposure' ./config.json)
v4l2-ctl -d /dev/video0 -c exposure_time_absolute=$(jq -r '.exposure_time_absolute' ./config.json)
v4l2-ctl -d /dev/video0 -c gain=$(jq -r '.gain' ./config.json)
v4l2-ctl -d /dev/video0 -c brightness=$(jq -r '.brightness' ./config.json)
v4l2-ctl -d /dev/video0 -c contrast=$(jq -r '.contrast' ./config.json)

foldername=$(date +"%Y-%m-%d-%H-%M-%S")
mkdir -p ./photos/$foldername

while true; do
    # Timestamp
    stamp=$(date +"%Y-%m-%d-%H-%M-%S")

    echo $(pwd)

    # Take a pic
    fswebcam -d $device_result -r $resolution --png 9 --no-banner -D 10 --save ./photos/$foldername/$stamp$fileformat

    # Upload to Cloud Storage
    #gcloud_upload="gcloud storage cp ../astrophotography/photos/$foldername/$stamp$fileformat $gsbucket/$foldername/$stamp$fileformat"
    gcloud_upload="gsutil cp ../astrophotography/photos/$foldername/$stamp$fileformat gs://$gsbucket/$foldername/$stamp$fileformat"
    echo "gcloud_upload: $gcloud_upload"

    # Pass gcloud upload command to gcloud_auth.sh
    upload=$(/bin/bash $path_to_gcloud_auth/gcloud_auth.sh "$gcloud_upload")

    #eom_result=$(eom -f ./photos/$foldername/$stamp$fileformat &)
    
    echo "device_result: $device_result"

    # Sleep
    sleep $pic_timer

    if [[ $upload =~ 'ERROR:' ]]; then
        echo "ERROR: $upload"
    else
        rm ./photos/$foldername/$stamp$fileformat
    fi
done
