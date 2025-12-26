# Astrophotography System

Automated photography capture and cloud storage system for Raspberry Pi with multi-profile support.

## Profiles

Switch between photography modes by changing `active_profile` in `config.json`:

- **astrophotography**: Low-light star photography (60s intervals, high gain)
- **aquarium**: Well-lit aquarium photography (30s intervals, fast exposure)  
- **daylight**: General daylight photography (15s intervals, low gain)

## Components

- **astrophotography.sh**: Captures images continuously with profile-specific camera settings
- **image_upload.sh**: Syncs images to Google Cloud Storage and cleans up local files
- **raspberrypi_startup.sh**: Updates code from git and restarts services on boot

## Setup

1. Install dependencies: `fswebcam`, `v4l-utils`, `jq`, `google-cloud-cli`
2. Configure service account key in `/home/d3/sa_key.json`
3. Add to crontab: `@reboot /home/d3/raspberrypi_startup.sh`
4. Set active profile in `config.json`

## Output

Images saved to folders like `astro-2024-01-01-12-00-00/` and uploaded to Google Cloud Storage.
