#!/bin/bash
set -euo pipefail

# 変数
export AWS_DEFAULT_REGION="ap-northeast-1"
DOMAIN_NAMES=("example.local")
VPC_ID="vpc-08ad5c00c7cdece78"

# エクスポート先を定義
mkdir -p export
EXPORT_DIR="./export"

# 確認メッセージ
for name in "${DOMAIN_NAMES[@]}"; do echo "$name"; done
read -r -p "上記ホストゾーンを取得します。よろしいですか？ (y/N): " yn
case "$yn" in [yY]*) ;; *) echo "処理を終了します." ; exit ;; esac

# メイン処理
for ((i=0; i < ${#DOMAIN_NAMES[*]}; i++)); do
  # ZoneIDを取得
  ZONE_ID=$(aws route53 list-hosted-zones-by-vpc --vpc-id $VPC_ID --vpc-region $AWS_DEFAULT_REGION --query "HostedZoneSummaries[?Name==\`${DOMAIN_NAMES[$i]}.\`].HostedZoneId" --output text)

  # リソースレコードをエクスポート
  echo "${DOMAIN_NAMES[$i]} のリソースレコードをエクスポートします。"
  aws route53 list-resource-record-sets --hosted-zone-id "$ZONE_ID" > "${EXPORT_DIR}"/"${AWS_DEFAULT_REGION}"_"${DOMAIN_NAMES[$i]}".json
  echo "${DOMAIN_NAMES[$i]} のリソースレコードをエクスポートしました。"
done
