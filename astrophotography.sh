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

# Extract profile-specific settings (load once at startup)
pic_timer=$(jq -r ".profiles.$active_profile.pic_timer" ./config.json)
file_format=$(jq -r ".profiles.$active_profile.file_format" ./config.json)
camera=$(jq -r ".profiles.$active_profile.camera" ./config.json)
resolution=$(jq -r ".profiles.$active_profile.resolution" ./config.json)
folder_prefix=$(jq -r ".profiles.$active_profile.folder_prefix" ./config.json)

# Load trigger settings once at startup
light_trigger_enabled=$(jq -r ".profiles.$active_profile.light_trigger_enabled" ./config.json)
light_threshold=$(jq -r ".profiles.$active_profile.light_threshold" ./config.json)
light_trigger_mode=$(jq -r ".profiles.$active_profile.light_trigger_mode" ./config.json)
time_trigger_enabled=$(jq -r ".profiles.$active_profile.time_trigger_enabled" ./config.json)
start_time=$(jq -r ".profiles.$active_profile.start_time" ./config.json)
stop_time=$(jq -r ".profiles.$active_profile.stop_time" ./config.json)
check_interval=$(jq -r ".profiles.$active_profile.check_interval" ./config.json)

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

# Light detection function
get_light_level() {
    if [[ "$device_result" != "" ]]; then
        # Take a quick test image and analyze brightness
        fswebcam -d $device_result -r $resolution --png 1 --no-banner -D 1 --save /tmp/light_test.png 2>/dev/null
        if [ -f /tmp/light_test.png ]; then
            # Use ImageMagick to get average brightness (0-100)
            light_level=$(convert /tmp/light_test.png -colorspace gray -format "%[fx:100*mean]" info: 2>/dev/null || echo "50")
            rm -f /tmp/light_test.png
            echo $light_level
        else
            echo "50"  # Default fallback
        fi
    else
        echo "50"  # Default fallback when no camera
    fi
}


# Initialize capture state
capturing="false"

# Main smart capture loop with inline decision logic
while true; do
    if [[ "$device_result" != "" ]]; then
        # Check trigger conditions directly in main loop
        time_ok="true"
        light_ok="true"
        
        # Check time trigger if enabled
        if [[ "$time_trigger_enabled" == "true" ]]; then
            current_time=$(date +"%H:%M")
            
            # Handle overnight periods (e.g., 20:00 to 06:00)
            if [[ "$start_time" > "$stop_time" ]]; then
                # Overnight schedule
                if [[ "$current_time" >= "$start_time" || "$current_time" <= "$stop_time" ]]; then
                    time_ok="true"
                else
                    time_ok="false"
                fi
            else
                # Same day schedule
                if [[ "$current_time" >= "$start_time" && "$current_time" <= "$stop_time" ]]; then
                    time_ok="true"
                else
                    time_ok="false"
                fi
            fi
            echo "Time trigger: $time_ok (current: $current_time, window: $start_time-$stop_time)"
        fi
        
        # Check light trigger if enabled
        if [[ "$light_trigger_enabled" == "true" ]]; then
            light_level=$(get_light_level)
            echo "Current light level: $light_level%, threshold: $light_threshold%, mode: $light_trigger_mode"
            
            if [[ "$light_trigger_mode" == "dark" ]]; then
                # Trigger when dark (light level below threshold)
                if (( $(echo "$light_level < $light_threshold" | bc -l) )); then
                    light_ok="true"
                else
                    light_ok="false"
                fi
            else
                # Trigger when bright (light level above threshold)
                if (( $(echo "$light_level > $light_threshold" | bc -l) )); then
                    light_ok="true"
                else
                    light_ok="false"
                fi
            fi
            echo "Light trigger: $light_ok"
        fi
        
        # Make capture decision in main loop
        if [[ "$time_ok" == "true" && "$light_ok" == "true" ]]; then
            # Conditions met - start/continue capturing
            if [[ "$capturing" != "true" ]]; then
                echo "Starting capture session - conditions met"
                capturing="true"
            fi
            
            # Generate timestamp for image filename
            stamp=$(date +"%Y-%m-%d-%H-%M-%S")
            
            # Capture image with profile settings
            fswebcam -d $device_result -r $resolution --png 9 --no-banner -D 10 --save $working_dir/photos/$foldername/$stamp$file_format
            
            # Use normal pic_timer for active capturing
            sleep_time=$pic_timer
        else
            # Conditions not met - stop capturing
            if [[ "$capturing" == "true" ]]; then
                echo "Stopping capture session - conditions not met"
                capturing="false"
            fi
            
            # Use check_interval when not capturing (less frequent checks)
            sleep_time=$check_interval
        fi
    else
        # No camera device found, use normal timer
        sleep_time=$pic_timer
    fi
    
    echo "sleeping for: $sleep_time seconds"
    sleep $sleep_time
done
