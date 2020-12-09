#!/bin/bash
set -euo pipefail

# 引数チェック
if [ "$#" -ne 1 ]; then
  echo "引数にバケット名を指定してください"
  exit 1
fi

# 変数
BUCKET_NAME="$1"

aws s3 rm s3://${BUCKET_NAME} --recursive
