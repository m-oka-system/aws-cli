#!/bin/bash
set -euo pipefail

# 変数
export AWS_DEFAULT_REGION="ap-northeast-1"
DOMAIN_NAME="example.local"
ZONE_ID="$@"

if [ "$#" -ne 1 ]; then
  echo  "ZoneIDを引数に指定してください。"
  exit 1
fi

# リソースレコードを削除
RECORD_COUNT=$(aws route53 list-resource-record-sets --hosted-zone-id $ZONE_ID --query "length(ResourceRecordSets)")
RECORD_COUNT=$((RECORD_COUNT - 2))
if [ "$RECORD_COUNT" -gt 0 ]; then
  echo "${RECORD_COUNT}個のリソースレコードが見つかりました。レコードを削除します"
  cat ./recordsets/${AWS_DEFAULT_REGION}_${DOMAIN_NAME}.json | sed -e 's/UPSERT/DELETE/g' > ./recordsets/${AWS_DEFAULT_REGION}_${DOMAIN_NAME}_delete.json
  aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONE_ID \
    --change-batch file://recordsets/${AWS_DEFAULT_REGION}_${DOMAIN_NAME}_delete.json 2>&1 1>/dev/null
  echo "リソースレコードを削除しました"
fi

# Delete hosted zone
echo "${DOMAIN_NAME}のホストゾーンを削除します。"
aws route53 delete-hosted-zone --id $ZONE_ID 2>&1 1>/dev/null
echo "${DOMAIN_NAME}のホストゾーンを削除しました。"
