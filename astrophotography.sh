#!/bin/bash
pic_timer=60
#fileformat=.jpg
fileformat=.png
device=$(v4l2-ctl --list-devices | grep -i 'FIBONAX Nova800' -A 1 | grep -i '/dev/video')

foldername=$(date +"%Y-%m-%d-%H-%M-%S")
mkdir -p ./photos/$foldername

#path_to_google_cloud_sdk=/home/d3
#export PATH="$path_to_google_cloud_sdk/google-cloud-sdk/bin:$PATH"

path_to_gcloud_auth=../gcloud_auth
sudo chmod +x $path_to_gcloud_auth/gcloud_auth.sh
glcoud_auth=$(/bin/bash $path_to_gcloud_auth/gcloud_auth.sh)
echo "glcoud_auth: $glcoud_auth"

#service_account=photos-push@sandcastle-401716.iam.gserviceaccount.com
#activate_account=(gcloud auth activate-service-account --key-file=./$service_account_keyfile_name --project=$service_account_project)
#echo "$activate_account"

while true; do
    # Timestamp
    stamp=$(date +"%Y-%m-%d-%H-%M-%S")

    # Take a pic
    #fswebcam -d $device -r 3264x2448 --jpeg 95 -D 1 $folderpath$stamp$fileformat --no-banner
    fswebcam -d $device -r 3264x2448 --png 9 ./photos/$foldername/$stamp$fileformat --no-banner

    # Upload to Cloud Storage
    echo "gcloud storage cp ./photos/$foldername/$stamp$fileformat gs://sandcastle-401716-photos/$foldername/$stamp$fileformat"
    upload=$(gcloud storage cp ./photos/$foldername/$stamp$fileformat gs://sandcastle-401716-photos/$foldername/$stamp$fileformat)
    echo "$upload"

    # Sleep
    sleep $pic_timer
done
