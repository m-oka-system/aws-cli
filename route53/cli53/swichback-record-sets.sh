#!/bin/bash
set -euo pipefail

# 変数
export AWS_DEFAULT_REGION="ap-northeast-1"
DOMAIN_NAME="example.local"
ZONE_ID="$*"

if [ "$#" -ne 1 ]; then
  echo  "ZoneIDを引数に指定してください。"
  exit 1
fi

# ホストゾーンに変更前のファイルをインポート
cli53 import --file "${AWS_DEFAULT_REGION}"_"${DOMAIN_NAME}"_"${ZONE_ID}"_before.txt --replace "$ZONE_ID"
