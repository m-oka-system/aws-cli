#!/bin/bash
set -euo pipefail

# 変数
export AWS_DEFAULT_REGION="ap-northeast-1"
DOMAIN_NAME="example.local"
ZONE_ID="$@"
MAP_FILE="dns-mapping.csv"

if [ "$#" -ne 1 ]; then
  echo  "ZoneIDを引数に指定してください。"
  exit 1
fi

# リソースレコードの更新用ファイルを1行ずつ読み込んで配列へ格納
mapfile -t RECORD_MAPPING_ARRAY < <(sed 1d $MAP_FILE | sed '/^#/d')

# リソースレコードをエクスポート
echo "リソースレコードをエクスポートします。"
cli53 export "$ZONE_ID" > ${AWS_DEFAULT_REGION}_${DOMAIN_NAME}_${ZONE_ID}_before.txt
cp ${AWS_DEFAULT_REGION}_${DOMAIN_NAME}_${ZONE_ID}_before.txt ${AWS_DEFAULT_REGION}_${DOMAIN_NAME}_${ZONE_ID}_after.txt

# レコードセットをマッピングファイルに従って更新
for record in "${RECORD_MAPPING_ARRAY[@]}"; do
  # Variables
  before=$(echo $record | cut -d , -f 2)
  after=$(echo $record | cut -d , -f 3)
  sed -i -e "s/${before}/${after}/" ${AWS_DEFAULT_REGION}_${DOMAIN_NAME}_${ZONE_ID}_after.txt
done

# ホストゾーンに変更後のファイルをインポート
cli53 import --file ${AWS_DEFAULT_REGION}_${DOMAIN_NAME}_${ZONE_ID}_after.txt --replace $ZONE_ID
