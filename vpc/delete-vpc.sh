#!/bin/bash

# Variables
export AWS_DEFAULT_REGION="ap-northeast-1"
VPC_NAME="awscli-vpc"
PUBLIC_SUBNET_NAMES=("awscli-public-subnet-1a" "awscli-public-subnet-1c")

# Delete public subnet
for (( i=0; i < ${#PUBLIC_SUBNET_NAMES[*]}; i++ )); do
  SUBNET_ID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=${PUBLIC_SUBNET_NAMES[$i]}" --query "Subnets[].SubnetId" --output text)
  aws ec2 delete-subnet --subnet-id "$SUBNET_ID"
done

# Delete vpc
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=${VPC_NAME}" --query "Vpcs[].VpcId" --output text)
aws ec2 delete-vpc --vpc-id "$VPC_ID"
