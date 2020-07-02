#!/bin/bash

# Variables
region="ap-northeast-1"
domainName="example.local"
vpcId="vpc-08f177c792bb6c5f3"

zoneId=$(aws route53 create-hosted-zone \
  --name $domainName \
  --vpc VPCRegion=$region,VPCId=$vpcId \
  --caller-reference `date +%Y-%m-%d_%H-%M-%S` \
  --query "HostedZone.Id" --output text)

# Create resource record sets
aws route53 change-resource-record-sets \
  --hosted-zone-id $zoneId \
  --change-batch file://recordsets/${region}_${domainName}.json