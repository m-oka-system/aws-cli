#!/bin/bash

# Variables
srcRegion="ap-northeast-1"
dstRegion="ap-southeast-1"
hostName="WEB01"
latestAmiId=$(aws ec2 describe-images --region $srcRegion --owner self --filter "Name=tag:Name,Values=$hostName*" --query "sort_by(Images, &CreationDate)[-1].ImageId" --output text)
latestAmiTagKeys=($(aws ec2 describe-images --region $srcRegion --owner self --image-id $latestAmiId --query 'sort_by(Images[].Tags[], &Key)[].Key' --output text))
latestAmiTagValues=($(aws ec2 describe-images --region $srcRegion --owner self --image-id $latestAmiId --query 'sort_by(Images[].Tags[], &Key)[].Value' --output text))
nowDate=`date +%Y-%m-%d-%H-%M-%S`

# Copy snapshot to Singapore region
CopiedImage=$(aws ec2 copy-image \
--region $dstRegion \
--source-region $srcRegion \
--name $hostName"_"$nowDate \
--description "Copied $latestAmiId from $dstRegion" \
--source-image-id $latestAmiId --output text)

# Copy tags to copied image from source image
for ((i=0; i < ${#latestAmiTagKeys[*]}; i++)); do
  aws ec2 create-tags --region $dstRegion --resources $CopiedImage --tags Key=${latestAmiTagKeys[$i]},Value=${latestAmiTagValues[$i]}
done