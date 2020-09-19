#!/bin/bash
set -euo pipefail

# 変数
export AWS_DEFAULT_REGION="ap-northeast-1"
DOMAIN_NAME="example.local"
ZONE_ID="$*"
LOG_FILE="r53_update.log"
EXPORT_DIR="./export"

if [ "$#" -ne 1 ]; then
  echo  "ZoneIDを引数に指定してください。"
  exit 1
fi

# ホストゾーンに変更前のファイルをインポート
echo "${DOMAIN_NAME} のリソースレコードを変更前の状態に更新します。"
date +%Y-%m-%d_%H-%M-%S >> $LOG_FILE
cli53 import --file "${EXPORT_DIR}"/"${AWS_DEFAULT_REGION}"_"${DOMAIN_NAME}"_"${ZONE_ID}"_before.txt --replace --dry-run "$ZONE_ID" >> $LOG_FILE
cli53 import --file "${EXPORT_DIR}"/"${AWS_DEFAULT_REGION}"_"${DOMAIN_NAME}"_"${ZONE_ID}"_before.txt --replace "$ZONE_ID"
echo "${DOMAIN_NAME} のリソースレコードの更新が終了しました。"
