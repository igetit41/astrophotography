#!/bin/bash

#device_result=$(v4l2-ctl --list-devices | grep -i 'FIBONAX Nova800' -A 1 | grep -i '/dev/video' | xargs)
#resolution=3264x2448
#device_result=$(v4l2-ctl --list-devices | grep -i 'USB 2.0 Camera' -A 1 | grep -i '/dev/video' | xargs)
#resolution=1920x1080

working_dir=/home/d3
gsbucket=$(jq -r '.gsbucket' ./config.json)
pic_timer=$(jq -r '.pic_timer' ./config.json)

local_prefix="$working_dir/photos/"
local_prefix_length=${#local_prefix}
echo "local_prefix_length: $local_prefix_length"

bucket_prefix="gs://$gsbucket/"
bucket_prefix_length=${#bucket_prefix}
echo "bucket_prefix_length: $bucket_prefix_length"

while true; do
    echo $working_dir
    ping -c 1 -q google.com >&/dev/null

    echo "ping: $?"
    if [ $? == 0 ]; then

        images_local=$(find $working_dir/photos -name "*.png" -print)
        echo "images_local: $images_local"

        gcloud_command="gcloud storage ls --recursive gs://$gsbucket/**"
        images_bucket=$(/bin/bash $working_dir/gcloud_auth/gcloud_auth.sh "$gcloud_command")
        images_bucket=$(echo "${images_bucket#*$bucket_prefix}")
        echo "images_bucket: $images_bucket"

        IFS=$'\n'
        read -rd '' -a images_local_array <<< "$images_local"
        echo "images_local_array: $images_local_array"

        read -rd '' -a images_bucket_array <<< "$images_bucket"
        images_bucket_array=("${images_bucket_array[@]:1}")
        echo "images_bucket_array: $images_bucket_array"

        for image_local in "${images_local_array[@]}";
        do
            echo "image_local: $image_local"
            image_local_trunk="${image_local:$local_prefix_length}"
            echo "image_local_trunk: $image_local_trunk"
            match_found="false"

            for image_bucket in "${images_bucket_array[@]}";
            do
                echo "image_bucket: $image_bucket"
                image_bucket_trunk="${image_bucket:$bucket_prefix_length}"
                echo "image_bucket_trunk: $image_bucket_trunk"

                if [[ "$image_local_trunk" == "$image_bucket_trunk" ]]; then
                    match_found="true"
                    break;
                fi
            done

            if [[ "$match_found" == "false" ]]; then
                gcloud_command="gsutil cp $image_local $bucket_prefix$image_local_trunk"
                echo "gcloud_command: $gcloud_command"
                upload=$(/bin/bash $working_dir/gcloud_auth/gcloud_auth.sh "$gcloud_command")
                echo $upload
                
                if [[ $upload =~ 'ERROR:' ]]; then
                    echo "ERROR: $upload"
                else
                    echo "delete image: $image_local"
                    rm $image_local
                fi
            fi
        done
    fi

    # Sleep
    echo "sleeping for: $pic_timer"
    sleep $pic_timer
done
