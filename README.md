# Astrophotography System

Automated photography capture and cloud storage system for Raspberry Pi with multi-profile support.

## Profiles

Switch between photography modes by changing `active_profile` in `config.json` (local; not committed):

- **astro_1** / **astro_2**: Low-light / dedicated camera profiles
- **aquarium**: Well-lit aquarium photography
- **daylight**: General daylight photography

## Components

- **astrophotography.sh**: Captures images continuously with profile-specific camera settings
- **image_upload.sh**: Syncs images to Google Cloud Storage and cleans up local files
- **raspberrypi_startup.sh**: Updates code from git and restarts services on boot

## Setup

1. Install dependencies: `fswebcam`, `v4l-utils`, `jq`, `google-cloud-cli`
2. Copy `config.json.example` → `config.json` and set `gsbucket` (and camera options) for your project
3. Place the upload service-account key at `/home/d3/sa_key.json` (gitignored; never commit)
4. Add to crontab: `@reboot /home/d3/raspberrypi_startup.sh`
5. Set `active_profile` in your local `config.json`

`config.json` and `sa_key.json` stay on the device only. The repo tracks `config.json.example` as the template.

## Output

Images saved to folders like `aquarium-2024-01-01-12-00-00/` and uploaded to the GCS bucket named in `config.json`.
