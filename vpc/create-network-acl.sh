#!/bin/bash

# Variables
region="ap-northeast-1"
vpcId="vpc-08f177c792bb6c5f3"
aclName="public_subnet_1a_acl"

# NetworkAclId=$(aws ec2 create-network-acl --region $region --vpc-id $vpcId --query "NetworkAcl.NetworkAclId" --output text)
NetworkAclId=$(aws ec2 describe-network-acls --region $region --filters "Name=tag-key,Values=Name" "Name=tag-value,Values=$aclName" --query "NetworkAcls[].NetworkAclId" --output text)
SubnetId=$(aws ec2 describe-network-acls --region $region --filters "Name=tag-key,Values=Name" "Name=tag-value,Values=$aclName" --query "NetworkAcls[].Associations[].SubnetId" --output text)
CidrBlock=$(aws ec2 describe-subnets --subnet-ids $SubnetId --query "Subnets[].CidrBlock" --output text)

aws ec2 create-network-acl-entry --region $region --network-acl-id $NetworkAclId --rule-number 100 --protocol -1 --cidr-block 0.0.0.0/0 --rule-action allow --egress
aws ec2 create-network-acl-entry --region $region --network-acl-id $NetworkAclId --rule-number 100 --protocol -1 --cidr-block 0.0.0.0/0 --rule-action allow --ingress
