#!/bin/bash
pic_timer=60
#fileformat=.jpg
fileformat=.png
device=$(v4l2-ctl --list-devices | grep -i 'FIBONAX Nova800' -A 1 | grep -i '/dev/video')

foldername=$(date +"%Y-%m-%d-%H-%M-%S")
mkdir -p ./photos/$foldername

path_to_gcloud_auth=../gcloud_auth
sudo chmod +x $path_to_gcloud_auth/gcloud_auth.sh
echo "glcoud_auth: $glcoud_auth"

while true; do
    # Timestamp
    stamp=$(date +"%Y-%m-%d-%H-%M-%S")

    # Take a pic
    #fswebcam -d $device -r 3264x2448 --jpeg 95 -D 1 $folderpath$stamp$fileformat --no-banner
    fswebcam -d $device -r 3264x2448 --png 9 ./photos/$foldername/$stamp$fileformat --no-banner

    # Upload to Cloud Storage
    gcloud_upload="gcloud storage cp ../astrophotography/photos/$foldername/$stamp$fileformat gs://sandcastle-401716-photos/$foldername/$stamp$fileformat"
    echo "gcloud_upload: $gcloud_upload"

    upload=$(/bin/bash $path_to_gcloud_auth/gcloud_auth.sh "$gcloud_upload")
    echo "upload: $upload"

    if [[ $upload =~ 'ERROR:' ]]; then
    else
        # Remove local copy
        rm ./photos/$foldername/$stamp$fileformat
    fi

    # Sleep
    sleep $pic_timer
done
