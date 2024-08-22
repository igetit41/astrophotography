#!/bin/bash
pic_timer=60
#pic_timer=5
fileformat=.png
path_to_gcloud_auth=../gcloud_auth
gsbucket=sandcastle-401716-photos

#device_pad="'"
#device_command="v4l2-ctl --list-devices | grep -i '${1}' -A 1 | grep -i '/dev/video'"
#device_resultx=$(v4l2-ctl --list-devices | grep -i $1 -A 1 | grep -i '/dev/video')
#resolution=$2

#device_result=$(v4l2-ctl --list-devices | grep -i 'FIBONAX Nova800' -A 1 | grep -i '/dev/video' | xargs)
#resolution=3264x2448

device_result=$(v4l2-ctl --list-devices | grep -i 'USB 2.0 Camera' -A 1 | grep -i '/dev/video' | xargs)
resolution=1920x1080

auto_exposure_result=$(v4l2-ctl -d $device_result --set-ctrl auto_exposure=3)
#cvlc_result=$(nohup cvlc -f v4l2://$device_result &)

foldername=$(date +"%Y-%m-%d-%H-%M-%S")
mkdir -p ./photos/$foldername

while true; do
    # Timestamp
    stamp=$(date +"%Y-%m-%d-%H-%M-%S")

    # Take a pic
    fswebcam -d $device_result -r $resolution --png 9 --no-banner --save ./photos/$foldername/$stamp$fileformat

    # Upload to Cloud Storage
    #gcloud_upload="gcloud storage cp ../astrophotography/photos/$foldername/$stamp$fileformat $gsbucket/$foldername/$stamp$fileformat"
    gcloud_upload="gsutil cp ../astrophotography/photos/$foldername/$stamp$fileformat gs://$gsbucket/$foldername/$stamp$fileformat"
    echo "gcloud_upload: $gcloud_upload"

    # Pass gcloud upload command to gcloud_auth.sh
    upload=$(/bin/bash $path_to_gcloud_auth/gcloud_auth.sh "$gcloud_upload")

    nohup eom -f ./photos/$foldername/$stamp$fileformat &
    
    echo "auto_exposure_result: $auto_exposure_result"

    # Sleep
    sleep $pic_timer

    if [[ $upload =~ 'ERROR:' ]]; then
        echo "ERROR: $upload"
    else
        rm ./photos/$foldername/$stamp$fileformat
    fi
done
