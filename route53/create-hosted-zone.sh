#!/bin/bash
set -euo pipefail

# 変数
export AWS_DEFAULT_REGION="ap-northeast-1"
DOMAIN_NAME="example.local"
VPC_ID="vpc-08ad5c00c7cdece78"

# プライベートホストゾーンを作成
echo "${DOMAIN_NAME}のホストゾーンを作成します。"
ZONE_ID=$(aws route53 create-hosted-zone \
  --name $DOMAIN_NAME \
  --vpc VPCRegion=$AWS_DEFAULT_REGION,VPCId=$VPC_ID \
  --caller-reference `date +%Y-%m-%d_%H-%M-%S` \
  --query "HostedZone.Id" --output text)
echo "${DOMAIN_NAME}のホストゾーンを作成しました。"

# リソースレコードを作成
echo "リソースレコードを作成します。"
aws route53 change-resource-record-sets \
  --hosted-zone-id $ZONE_ID \
  --change-batch file://recordsets/${AWS_DEFAULT_REGION}_${DOMAIN_NAME}.json 2>&1 1>/dev/null
echo "リソースレコードを作成しました"
