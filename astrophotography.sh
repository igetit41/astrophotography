#!/bin/bash
pic_timer=60
#pic_timer=5
fileformat=.png
path_to_gcloud_auth=../gcloud_auth
gsbucket=sandcastle-401716-photos

device="'${1}'"
device_resultx=$(v4l2-ctl --list-devices | grep -i $device -A 1 | grep -i '/dev/video' | xargs)

#resolution=$2
#device_result=$(v4l2-ctl --list-devices | grep -i 'FIBONAX Nova800' -A 1 | grep -i '/dev/video' | xargs)
#resolution=3264x2448

device_result=$(v4l2-ctl --list-devices | grep -i 'USB 2.0 Camera' -A 1 | grep -i '/dev/video' | xargs)
resolution=1920x1080

#auto_exposure_result=$(v4l2-ctl -d $device_result --set-ctrl auto_exposure=3)
#set_controls_result=$(v4l2-ctl -d $device_result -c auto_exposure=1 -c exposure_time_absolute=5000 -c brightness=30 -c gain=50 -c contrast=32)

#cvlc_result=$(nohup cvlc -f v4l2://$device_result &)

v4l2-ctl -d /dev/video0 -c auto_exposure=1
v4l2-ctl -d /dev/video0 -c exposure_time_absolute=5000
v4l2-ctl -d /dev/video0 -c gain=100
v4l2-ctl -d /dev/video0 -c brightness=64
v4l2-ctl -d /dev/video0 -c contrast=64

foldername=$(date +"%Y-%m-%d-%H-%M-%S")
mkdir -p ./photos/$foldername

while true; do
    # Timestamp
    stamp=$(date +"%Y-%m-%d-%H-%M-%S")

    # Take a pic
    fswebcam -d $device_result -r $resolution --png 9 --no-banner -D 10 --save ./photos/$foldername/$stamp$fileformat

    # Upload to Cloud Storage
    #gcloud_upload="gcloud storage cp ../astrophotography/photos/$foldername/$stamp$fileformat $gsbucket/$foldername/$stamp$fileformat"
    gcloud_upload="gsutil cp ../astrophotography/photos/$foldername/$stamp$fileformat gs://$gsbucket/$foldername/$stamp$fileformat"
    echo "gcloud_upload: $gcloud_upload"

    # Pass gcloud upload command to gcloud_auth.sh
    upload=$(/bin/bash $path_to_gcloud_auth/gcloud_auth.sh "$gcloud_upload")

    #eom_result=$(eom -f ./photos/$foldername/$stamp$fileformat &)
    
    echo "device_resultx: $device_resultx"

    # Sleep
    sleep $pic_timer

    if [[ $upload =~ 'ERROR:' ]]; then
        echo "ERROR: $upload"
    else
        rm ./photos/$foldername/$stamp$fileformat
    fi
done
