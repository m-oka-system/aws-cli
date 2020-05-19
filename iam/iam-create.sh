#!/bin/bash

HostName=WEB01

# Create IAM role
aws iam create-role \
  --role-name $HostName"_IAMROLE" \
  --assume-role-policy-document file://iamrole.json

# Create IAM policy
IAMPOLICY_ARN=$(aws iam create-policy \
  --policy-name $HostName"_IAMPOLICY" \
  --policy-document file://iampolicy.json \
  --output text --query "Policy.Arn")

# Attach policy to IAM role
aws iam attach-role-policy \
  --policy-arn $IAMPOLICY_ARN \
  --role-name $HostName"_IAMROLE"

# Create instance profile
aws iam create-instance-profile \
  --instance-profile-name $HostName"_IAMROLE"

# Add IAM role to instance profile
aws iam add-role-to-instance-profile \
  --role-name $HostName"_IAMROLE" \
  --instance-profile-name $HostName"_IAMROLE"