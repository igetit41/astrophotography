#!/bin/bash
# Automated image upload to Google Cloud Storage with smart sync

# Legacy camera configurations (commented out)
#device_result=$(v4l2-ctl --list-devices | grep -i 'FIBONAX Nova800' -A 1 | grep -i '/dev/video' | xargs)
#resolution=3264x2448
#device_result=$(v4l2-ctl --list-devices | grep -i 'USB 2.0 Camera' -A 1 | grep -i '/dev/video' | xargs)
#resolution=1920x1080

# Set working directory
working_dir=/home/d3

# Get active profile
active_profile=$(jq -r '.active_profile' ./config.json)
echo "Active profile: $active_profile"

# Extract profile-specific settings
gsbucket=$(jq -r ".profiles.$active_profile.gsbucket" ./config.json)
pic_timer=$(jq -r ".profiles.$active_profile.pic_timer" ./config.json)

# Set up path prefixes for comparison
local_prefix="$working_dir/photos/"
local_prefix_length=${#local_prefix}
echo "local_prefix_length: $local_prefix_length"

bucket_prefix="gs://$gsbucket/"
bucket_prefix_length=${#bucket_prefix}
echo "bucket_prefix_length: $bucket_prefix_length"

# Main upload loop
while true; do
    echo $working_dir
    # Check internet connectivity
    ping -c 1 -q google.com >&/dev/null

    echo "ping: $?"
    if [ $? == 0 ]; then
        # Find all local PNG images
        images_local=$(find $working_dir/photos -name "*.png" -print)
        echo "images_local: $images_local"

        # Get list of images already in cloud bucket
        gcloud_command="gcloud storage ls --recursive gs://$gsbucket/**"
        images_bucket=$(/bin/bash $working_dir/gcloud_auth/gcloud_auth.sh "$gcloud_command")
        images_bucket=$(echo "${images_bucket#*$bucket_prefix}")
        echo "images_bucket: $images_bucket"

        # Convert image lists to arrays for processing
        IFS=$'\n'
        read -rd '' -a images_local_array <<< "$images_local"
        echo "images_local_array: $images_local_array"

        read -rd '' -a images_bucket_array <<< "$images_bucket"
        images_bucket_array=("${images_bucket_array[@]:1}")
        echo "images_bucket_array: $images_bucket_array"

        # Process each local image
        for image_local in "${images_local_array[@]}";
        do
            echo "image_local: $image_local"
            # Extract relative path for comparison
            image_local_trunk="${image_local:$local_prefix_length}"
            echo "image_local_trunk: $image_local_trunk"
            match_found="false"

            # Check if image already exists in bucket
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

            # Upload image if not found in bucket
            if [[ "$match_found" == "false" ]]; then
                gcloud_command="gsutil cp $image_local $bucket_prefix$image_local_trunk"
                echo "gcloud_command: $gcloud_command"
                upload=$(/bin/bash $working_dir/gcloud_auth/gcloud_auth.sh "$gcloud_command")
                echo $upload
                
                # Delete local image after successful upload
                if [[ $upload =~ 'ERROR:' ]]; then
                    echo "ERROR: $upload"
                else
                    echo "delete image: $image_local"
                    rm $image_local
                fi
            fi
        done
    fi

    # Wait before next sync cycle
    echo "sleeping for: $pic_timer"
    sleep $pic_timer
done
