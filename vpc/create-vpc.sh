#!/bin/bash

# Common Variables
REGION="ap-northeast-1"

# VPC
VPC_NAME="awscli-vpc"
VPC_CIDR_BLOCK="10.100.0.0/16"

# Subnet
PUBLIC_SUBNET_NAMES=("awscli-public-subnet-1a" "awscli-public-subnet-1c")
PUBLIC_SUBNET_CIDR_BLOCKS=("10.100.11.0/24" "10.100.12.0/24")
PUBLIC_SUBNET_AZ=("${REGION}a" "${REGION}c")

# Create vpc
VPC_ID=$(aws ec2 create-vpc --region $REGION \
  --cidr-block $VPC_CIDR_BLOCK \
  --instance-tenancy default \
  --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=$VPC_NAME},{Key=Env,Value=Dev}]" \
  --query "Vpc.VpcId" --output text)

# Create public subnet
for (( i=0; i < ${#PUBLIC_SUBNET_NAMES[*]}; i++ )); do
  aws ec2  create-subnet --region $REGION \
  --vpc-id $VPC_ID \
  --cidr-block ${PUBLIC_SUBNET_CIDR_BLOCKS[$i]} \
  --availability-zone ${PUBLIC_SUBNET_AZ[$i]} \
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=${PUBLIC_SUBNET_NAMES[$i]}},{Key=Env,Value=Dev}]"
done


# aws ec2 create-internet-gateway


