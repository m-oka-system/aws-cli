#!/bin/bash

# Variables
region="ap-northeast-1"
domainName="example.local"
vpcId="vpc-08f177c792bb6c5f3"
zoneId=$(aws route53 list-hosted-zones-by-vpc --vpc-id $vpcId --vpc-region $region --query "HostedZoneSummaries[?Name==\`${domainName}.\`].HostedZoneId" --output text)

# Delete resource record sets
cat ./recordsets/${region}_${domainName}.json | sed -e 's/UPSERT/DELETE/g' > ./recordsets/${region}_${domainName}_delete.json
aws route53 change-resource-record-sets \
  --hosted-zone-id $zoneId \
  --change-batch file://recordsets/${region}_${domainName}_delete.json

# Delete hosted zone
aws route53 delete-hosted-zone --id $zoneId