#!/bin/bash
set -euo pipefail

# 変数
export AWS_DEFAULT_REGION="ap-northeast-1"
DOMAIN_NAME="example.local"
ZONE_ID="$*"
MAP_FILE="dns-mapping.csv"
LOG_FILE="r53_update.log"

# エクスポート先を定義
mkdir -p export
EXPORT_DIR="./export"

if [ "$#" -ne 1 ]; then
  echo  "ZoneIDを引数に指定してください。"
  exit 1
fi

echo "リソースレコードの更新処理を開始します。"

# リソースレコードの更新用ファイルを1行ずつ読み込んで配列へ格納
mapfile -t RECORD_MAPPING_ARRAY < <(sed 1d $MAP_FILE | sed '/^#/d')

# リソースレコードをエクスポート
echo "${DOMAIN_NAME} のリソースレコードをエクスポートします。"
cli53 export "$ZONE_ID" > "${EXPORT_DIR}"/"${AWS_DEFAULT_REGION}"_"${DOMAIN_NAME}"_"${ZONE_ID}"_before.txt
cp "${EXPORT_DIR}"/"${AWS_DEFAULT_REGION}"_"${DOMAIN_NAME}"_"${ZONE_ID}"_before.txt "${EXPORT_DIR}"/"${AWS_DEFAULT_REGION}"_"${DOMAIN_NAME}"_"${ZONE_ID}"_after.txt

# AWSCLIでJSONをエクスポート（確認用）
aws route53 list-resource-record-sets --hosted-zone-id "$ZONE_ID" > "${EXPORT_DIR}"/"${AWS_DEFAULT_REGION}"_"${DOMAIN_NAME}"_"${ZONE_ID}"_before.json

# レコードセットをマッピングファイルに従って更新
echo "${DOMAIN_NAME} のマッピングファイルに従ってリソースレコードファイルを更新します。"
for record in "${RECORD_MAPPING_ARRAY[@]}"; do
  # Variables
  before=$(echo "$record" | cut -d , -f 2)
  after=$(echo "$record" | cut -d , -f 3)
  sed -i -e "s/${before}/${after}/" "${EXPORT_DIR}"/"${AWS_DEFAULT_REGION}"_"${DOMAIN_NAME}"_"${ZONE_ID}"_after.txt
done

# ホストゾーンに変更後のファイルをインポート
echo "更新したリソースレコードをホストゾーンにインポートします。"
date +%Y-%m-%d_%H-%M-%S >> $LOG_FILE
cli53 import --file "${EXPORT_DIR}"/"${AWS_DEFAULT_REGION}"_"${DOMAIN_NAME}"_"${ZONE_ID}"_after.txt --replace --dry-run "$ZONE_ID" >> $LOG_FILE
cli53 import --file "${EXPORT_DIR}"/"${AWS_DEFAULT_REGION}"_"${DOMAIN_NAME}"_"${ZONE_ID}"_after.txt --replace "$ZONE_ID"

# AWSCLIでJSONをエクスポート（確認用）
aws route53 list-resource-record-sets --hosted-zone-id "$ZONE_ID" > "${EXPORT_DIR}"/"${AWS_DEFAULT_REGION}"_"${DOMAIN_NAME}"_"${ZONE_ID}"_after.json

echo "リソースレコードの更新処理が終了しました。"
