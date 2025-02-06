#!/bin/bash

gcloud_command=$1

#Copy this whole folder one directory up and add sa_json.json keyfile into the same directory
service_account=$(jq -r '.client_email' ../sa_key.json)
service_account_project=$(jq -r '.project_id' ../sa_key.json)

set_account=$(gcloud config set account $service_account)
if [[ $set_account != '' ]]; then
    echo "set_account: $set_account"
fi

activate_account=$(gcloud auth activate-service-account --key-file=../sa_key.json --project=$service_account_project)
if [[ $activate_account != '' ]]; then
    echo "activate_account: $activate_account"
fi

gcloud_command_result=$($gcloud_command)
if [[ $gcloud_command_result != '' ]]; then
    echo "$gcloud_command_result"
fi
