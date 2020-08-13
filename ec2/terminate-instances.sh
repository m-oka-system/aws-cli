#!/bin/bash

# Variables
servers="$@"

if [ "$#" -eq 0 ]; then
  echo  "1つ以上の引数を指定してください。"
  exit 1
fi

for i in ${servers[@]}; do
  hostName=$i
  InstanceId=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$hostName" "Name=instance-state-name,Values=running" --query "Reservations[].Instances[].InstanceId" --output text)
  # Disable delete protection
  aws ec2 modify-instance-attribute --instance-id $InstanceId --no-disable-api-termination
  # Delete EC2 instances
  aws ec2 terminate-instances --instance-ids $InstanceId
done
