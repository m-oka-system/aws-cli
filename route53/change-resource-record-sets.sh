#!/bin/bash
set -euo pipefail

# 共通
export AWS_DEFAULT_REGION="ap-northeast-1"
DOMAIN_NAME="example.local"
VPC_ID="vpc-08ad5c00c7cdece78"
ZONE_ID=$(aws route53 list-hosted-zones-by-vpc --vpc-id $VPC_ID --vpc-region $AWS_DEFAULT_REGION --query "HostedZoneSummaries[?Name==\`${DOMAIN_NAME}.\`].HostedZoneId" --output text)

# リソースレコードを更新
echo "リソースレコードを更新します。"
aws route53 change-resource-record-sets \
--hosted-zone-id "$ZONE_ID" \
--change-batch file://recordsets/${AWS_DEFAULT_REGION}_${DOMAIN_NAME}.json > /dev/null 2>&1
echo "リソースレコードを更新しました。"
