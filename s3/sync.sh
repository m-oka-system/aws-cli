#!/bin/bash
set -euo pipefail

# 引数チェック
if [ "$#" -ne 1 ]; then
  echo "引数にバケット名を指定してください"
  exit 1
fi

# 変数
BUCKET_NAME="$1"
SOURCE1="../ssm/run_command/ping/"
SOURCE2="../ssm/run_command/windows/"

aws s3 sync $SOURCE1 s3://${BUCKET_NAME}/ping
aws s3 sync $SOURCE2 s3://${BUCKET_NAME}/windows
