#!/bin/bash

# Variables
region="ap-northeast-1"
vpcId="vpc-08f177c792bb6c5f3"
domainNames=("example.local" "11.0.10")

# Main
for name in ${domainNames[@]}; do echo $name; done
read -p "上記ホストゾーンを取得します。よろしいですか？ (y/N): " yn
case "$yn" in [yY]*) ;; *) echo "処理を終了します." ; exit ;; esac

echo "---start---"

for ((i=0; i < ${#domainNames[*]}; i++)); do
  # Get hosted zone id
  echo "Get hosted zone id(${domainNames[$i]})"
  zoneId=$(aws route53 list-hosted-zones-by-vpc --vpc-id $vpcId --vpc-region $region --query "HostedZoneSummaries[?Name==\`${domainNames[$i]}.\`].HostedZoneId" --output text)

  # Export resource record sets
  echo "Export resource record sets(${domainNames[$i]})"
  aws route53 list-resource-record-sets --hosted-zone-id $zoneId > ${region}_${domainNames[$i]}.json
done

echo "---finished---"
