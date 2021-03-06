#!/bin/bash
set -euo pipefail

# 変数
export AWS_DEFAULT_REGION="ap-northeast-1"
DOMAIN_NAME="example.local"
VPC_ID="vpc-08ad5c00c7cdece78"
ZONE_ID=$(aws route53 list-hosted-zones-by-vpc --vpc-id $VPC_ID --vpc-region $AWS_DEFAULT_REGION --query "HostedZoneSummaries[?Name==\`${DOMAIN_NAME}.\`].HostedZoneId" --output text)

# リソースレコードを削除
RECORD_COUNT=$(aws route53 list-resource-record-sets --hosted-zone-id "$ZONE_ID" --query "length(ResourceRecordSets)")
RECORD_COUNT=$((RECORD_COUNT - 2))
if [ "$RECORD_COUNT" -gt 0 ]; then
  echo "${RECORD_COUNT}個のリソースレコードが見つかりました。レコードを削除します"
  sed -e 's/UPSERT/DELETE/g' recordsets/${AWS_DEFAULT_REGION}_${DOMAIN_NAME}.json > ./recordsets/${AWS_DEFAULT_REGION}_${DOMAIN_NAME}_delete.json
  aws route53 change-resource-record-sets \
    --hosted-zone-id "$ZONE_ID" \
    --change-batch file://recordsets/${AWS_DEFAULT_REGION}_${DOMAIN_NAME}_delete.json > /dev/null 2>&1
  echo "リソースレコードを削除しました"
fi

# Delete hosted zone
echo "${DOMAIN_NAME}のホストゾーンを削除します。"
aws route53 delete-hosted-zone --id "$ZONE_ID" > /dev/null 2>&1
echo "${DOMAIN_NAME}のホストゾーンを削除しました。"
