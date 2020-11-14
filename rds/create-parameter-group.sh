#!/bin/bash
set -euo pipefail

# 変数
DB_INSTANCE_IDENTIFIER="$*"
DB_PARAMETER_GROUP_NAME=${DB_INSTANCE_IDENTIFIER}-parameter-group
DB_PARAMETER_GROUP_FAMILY="mysql8.0"

if [ "$#" -ne 1 ]; then
  echo  "RDSのホスト名を引数に指定してください。"
  exit 1
fi

# 確認メッセージ
read -r -p "${DB_INSTANCE_IDENTIFIER} のパラメータグループを作成します。よろしいですか？ (y/N): " yn
case "$yn" in [yY]*) ;; *) echo "処理を終了します." ; exit ;; esac

# パラメータグループを作成
aws rds create-db-parameter-group \
  --db-parameter-group-name $DB_PARAMETER_GROUP_NAME \
  --db-parameter-group-family $DB_PARAMETER_GROUP_FAMILY \
  --description $DB_PARAMETER_GROUP_NAME \
  --tags Key=Name,Value=$DB_PARAMETER_GROUP_NAME Key=env,Value=dev
