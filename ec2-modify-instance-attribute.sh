#!/bin/bash

# Variables
region="ap-northeast-1"
instanceId=""

aws ec2 modify-instance-attribute --region $region \
  --instance-id $instanceId \
  --no-source-dest-check