#!/bin/bash

# EC2 metadata
AWS_AVAIL_ZONE=$(curl http://169.254.169.254/latest/meta-data/placement/availability-zone)
AWS_REGION="`echo \"$AWS_AVAIL_ZONE\" | sed 's/[a-z]$//'`"
AWS_INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)
ROOT_VOLUME_IDS=$(aws ec2 describe-instances --region $AWS_REGION --instance-id $AWS_INSTANCE_ID --output text --query Reservations[0].Instances[0].BlockDeviceMappings[0].Ebs.VolumeId)
DATA_VOLUME_IDS=$(aws ec2 describe-instances --region $AWS_REGION --instance-id $AWS_INSTANCE_ID --output text --query Reservations[0].Instances[0].BlockDeviceMappings[].Ebs.VolumeId)
NETWORK_INTERFACE_IDS=$(aws ec2 describe-instances --region $AWS_REGION --instance-id $AWS_INSTANCE_ID --output text --query Reservations[0].Instances[0].NetworkInterfaces[].NetworkInterfaceId)

# variables
hostName=$(aws ec2 describe-instances --region $AWS_REGION --instance-id $AWS_INSTANCE_ID --output text --query 'Reservations[].Instances[].Tags[?Key==`Name`].Value')

# timezone
timedatectl set-timezone "Asia/Tokyo"

# locale
localectl set-locale LANG=ja_JP.utf8
localectl set-keymap jp106
source /etc/locale.conf

# hostname
hostnamectl set-hostname --static $hostName
echo "preserve_hostname: true" >> /etc/cloud/cloud.cfg

# Add tags to ebs volume
aws ec2 create-tags --resources $DATA_VOLUME_IDS --region $AWS_REGION --tags Key=Name,Value=$hostName"_DATA"
aws ec2 create-tags --resources $ROOT_VOLUME_IDS --region $AWS_REGION --tags Key=Name,Value=$hostName"_ROOT"

# Add tags to network interface
aws ec2 create-tags --resources $NETWORK_INTERFACE_IDS --region $AWS_REGION --tags Key=Name,Value=$hostName"_ENI"

# restart computer
reboot
