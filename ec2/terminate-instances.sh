#!/bin/bash

# Variables
hostName="WEB02"
InstanceId=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$hostName" "Name=instance-state-name,Values=running" --query "Reservations[].Instances[].InstanceId" --output text)

# Disable delete protection
aws ec2 modify-instance-attribute --instance-id $InstanceId --no-disable-api-termination
# Delete EC2 instances
aws ec2 terminate-instances --instance-ids $InstanceId 2>&1 1> /dev/null