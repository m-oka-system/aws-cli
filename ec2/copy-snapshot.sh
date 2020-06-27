#!/bin/bash

# Variables
srcRegion="ap-northeast-1"
dstRegion="ap-southeast-1"
hostName="WEB01"
snapshotIds=$(aws ec2 describe-snapshots --filters "Name=tag:Name,Values=$hostName*" --query "reverse(sort_by(Snapshots, &StartTime))[:1].SnapshotId" --output text)

# Copy snapshot to Singapore region
aws ec2 copy-snapshot \
  --region $dstRegion \
  --source-region $srcRegion \
  --source-snapshot-id $snapshotIds \
  --tag-specifications "ResourceType=snapshot,Tags=[{Key=Name,Value=${hostName}},{Key=env,Value=dev}]"