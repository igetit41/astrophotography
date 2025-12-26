#!/bin/bash
# Automated photography capture script with multi-profile support

# Legacy camera configurations (commented out)
#device_result=$(v4l2-ctl --list-devices | grep -i 'FIBONAX Nova800' -A 1 | grep -i '/dev/video' | xargs)
#resolution=3264x2448
#device_result=$(v4l2-ctl --list-devices | grep -i 'USB 2.0 Camera' -A 1 | grep -i '/dev/video' | xargs)
#resolution=1920x1080

# Set working directory
working_dir=/home/d3
echo $working_dir

# Get active profile
active_profile=$(jq -r '.active_profile' ./config.json)
echo "Active profile: $active_profile"

# Extract profile-specific settings
pic_timer=$(jq -r ".profiles.$active_profile.pic_timer" ./config.json)
file_format=$(jq -r ".profiles.$active_profile.file_format" ./config.json)
camera=$(jq -r ".profiles.$active_profile.camera" ./config.json)
resolution=$(jq -r ".profiles.$active_profile.resolution" ./config.json)
folder_prefix=$(jq -r ".profiles.$active_profile.folder_prefix" ./config.json)

# Find camera device
device_result=$(v4l2-ctl --list-devices | grep -i "$camera" -A 1 | grep -i '/dev/video' | xargs)
echo "device_result: $device_result"

# Configure camera if device found
if [[ "$device_result" != "" ]]; then
    # Apply profile-specific camera settings
    v4l2-ctl -d /dev/video0 -c auto_exposure=$(jq -r ".profiles.$active_profile.auto_exposure" ./config.json)
    v4l2-ctl -d /dev/video0 -c exposure_time_absolute=$(jq -r ".profiles.$active_profile.exposure_time_absolute" ./config.json)
    v4l2-ctl -d /dev/video0 -c gain=$(jq -r ".profiles.$active_profile.gain" ./config.json)
    v4l2-ctl -d /dev/video0 -c brightness=$(jq -r ".profiles.$active_profile.brightness" ./config.json)
    v4l2-ctl -d /dev/video0 -c contrast=$(jq -r ".profiles.$active_profile.contrast" ./config.json)
    v4l2-ctl -d /dev/video0 -c saturation=$(jq -r ".profiles.$active_profile.saturation" ./config.json)

    # Create timestamped folder with profile prefix
    foldername="${folder_prefix}-$(date +"%Y-%m-%d-%H-%M-%S")"
    mkdir -p $working_dir/photos/$foldername
    echo "Created folder: $working_dir/photos/$foldername"
fi

# Main capture loop
while true; do
    if [[ "$device_result" != "" ]]; then
        # Generate timestamp for image filename
        stamp=$(date +"%Y-%m-%d-%H-%M-%S")

        # Capture image with profile settings
        fswebcam -d $device_result -r $resolution --png 9 --no-banner -D 10 --save $working_dir/photos/$foldername/$stamp$file_format
    fi
    
    # Wait for next capture based on profile timing
    echo "sleeping for: $pic_timer"
    sleep $pic_timer
done
