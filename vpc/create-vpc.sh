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
declare -a PUBLIC_SUBNET_IDS=()
for (( i=0; i < ${#PUBLIC_SUBNET_NAMES[*]}; i++ )); do
  PUBLIC_SUBNET_ID=$(aws ec2  create-subnet --region $REGION \
  --vpc-id $VPC_ID \
  --cidr-block ${PUBLIC_SUBNET_CIDR_BLOCKS[$i]} \
  --availability-zone ${PUBLIC_SUBNET_AZ[$i]} \
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=${PUBLIC_SUBNET_NAMES[$i]}},{Key=Env,Value=Dev}]" \
  --query "Subnet.SubnetId" --output text)
  PUBLIC_SUBNET_IDS+=($PUBLIC_SUBNET_ID)
done

# Create internet gateway
INTERNET_GATEWAY_ID=$(aws ec2 create-internet-gateway --region $REGION \
  --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=${VPC_NAME}-igw},{Key=Env,Value=Dev}]" \
  --query "InternetGateway.InternetGatewayId" --output text)

# Attach internet gateway to vpc
aws ec2 attach-internet-gateway --region $REGION --internet-gateway-id $INTERNET_GATEWAY_ID --vpc-id $VPC_ID

# Create route table for public subnet
declare -a ROUTE_TABLE_IDS=()
for (( i=0; i < ${#PUBLIC_SUBNET_NAMES[*]}; i++ )); do
  ROUTE_TABLE_ID=$(aws ec2 create-route-table --region $REGION \
    --vpc-id $VPC_ID \
    --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=${PUBLIC_SUBNET_NAMES[$i]}-rt},{Key=Env,Value=Dev}]" \
    --query "RouteTable.RouteTableId" --output text)
    ROUTE_TABLE_IDS+=($ROUTE_TABLE_ID)
done

# Create route in route table
for (( i=0; i < ${#ROUTE_TABLE_IDS[*]}; i++ )); do
  aws ec2 create-route --region $REGION \
    --route-table-id ${ROUTE_TABLE_IDS[$i]} \
    --destination-cidr-block 0.0.0.0/0 \
    --gateway-id $INTERNET_GATEWAY_ID
done

# Associate route table with subnet
for (( i=0; i < ${#ROUTE_TABLE_IDS[*]}; i++ )); do
  aws ec2 associate-route-table --region $REGION \
    --route-table-id ${ROUTE_TABLE_IDS[$i]} \
    --subnet-id ${PUBLIC_SUBNET_IDS[$i]}
done
