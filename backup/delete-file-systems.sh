#!/usr/bin/env bash

set -e

# Common Variables
region="ap-southeast-1"
fileSystemIds=($(aws efs describe-file-systems --region $region --query "FileSystems[].FileSystemId" --output text))

# Delete EFS
for i in ${fileSystemIds[@]}; do
  echo $i
  aws efs delete-file-system --region $region --file-system-id $i
done
