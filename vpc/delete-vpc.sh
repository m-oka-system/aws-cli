#!/bin/bash

# Variables
REGION="ap-northeast-1"
VPC_NAME="awscli-vpc"
PUBLIC_SUBNET_NAMES=("awscli-public-subnet-1a" "awscli-public-subnet-1c")

# Delete public subnet
for (( i=0; i < ${#PUBLIC_SUBNET_NAMES[*]}; i++ )); do
  SUBNET_ID=$(aws ec2 describe-subnets --region $REGION --filters "Name=tag:Name,Values=${PUBLIC_SUBNET_NAMES[$i]}" --query "Subnets[].SubnetId" --output text)
  aws ec2 delete-subnet --region $REGION --subnet-id $SUBNET_ID
done

# Delete vpc
VPC_ID=$(aws ec2 describe-vpcs --region $REGION --filters "Name=tag:Name,Values=${VPC_NAME}" --query "Vpcs[].VpcId" --output text)
aws ec2 delete-vpc --region $REGION --vpc-id $VPC_ID
