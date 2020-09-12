#!/bin/bash

# Variables
region="ap-northeast-1"
domainName="example.local"
zoneId="$@"

if [ "$#" -ne 1 ]; then
  echo  "ZoneIDを引数に指定してください。"
  exit 1
fi

# Delete resource record sets
cat ./recordsets/${region}_${domainName}.json | sed -e 's/UPSERT/DELETE/g' > ./recordsets/${region}_${domainName}_delete.json
aws route53 change-resource-record-sets \
  --hosted-zone-id $zoneId \
  --change-batch file://recordsets/${region}_${domainName}_delete.json

# Delete hosted zone
aws route53 delete-hosted-zone --id $zoneId
