#!/bin/bash

#device_result=$(v4l2-ctl --list-devices | grep -i 'FIBONAX Nova800' -A 1 | grep -i '/dev/video' | xargs)
#resolution=3264x2448
#device_result=$(v4l2-ctl --list-devices | grep -i 'USB 2.0 Camera' -A 1 | grep -i '/dev/video' | xargs)
#resolution=1920x1080

working_dir=/home/d3
gsbucket=$(jq -r '.gsbucket' ./config.json)
pic_timer=$(jq -r '.pic_timer' ./config.json)

while true; do
    echo $working_dir
    ping -c 1 -q google.com >&/dev/null

    echo "ping: $?"
    if [ $? == 0 ]; then

        images_local=$(find $working_dir/photos -print)

        gcloud_command="gcloud storage ls --recursive gs://$gsbucket/**"
        images_bucket=$(/bin/bash $working_dir/gcloud_auth/gcloud_auth.sh "$gcloud_command")

        IFS='\n'
        read -ra images_local_array <<< "$images_local"
        read -ra images_bucket_array <<< "$images_bucket"

        local_prefix="$working_dir/photos/"
        local_prefix_length=${#str}
        echo $local_prefix_length

        bucket_prefix="gs://$gsbucket/"
        bucket_prefix_length=${#str}
        echo $bucket_prefix_length

        for image_local in $images_local_array;
        do
            echo $image_local
            image_local_trunk="${image_local:$local_prefix_length}"
            echo $image_local_trunk
            match_found="false"

            for image_bucket in $images_bucket_array;
            do
                echo $image_bucket
                image_bucket_trunk="${image_bucket:$bucket_prefix_length}"
                echo $image_bucket_trunk

                if [[ "$image_local_trunk" == "$image_bucket_trunk" ]]; then
                    match_found="true"
                    break;
                fi
            done
            if [[ "$match_found" == "false" ]]; then
                gcloud_command="gsutil cp $image_local $bucket_prefix$image_local_trunk"
                echo "gcloud_upload: $gcloud_upload"
                upload=$(/bin/bash $working_dir/gcloud_auth/gcloud_auth.sh "$gcloud_command")
                echo $upload
                
                if [[ $upload =~ 'ERROR:' ]]; then
                    echo "ERROR: $upload"
                else
                    rm $image_local
                fi
            fi
        done
    fi

    # Sleep
    sleep $pic_timer
done
