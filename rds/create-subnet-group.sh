#!/bin/bash
set -euo pipefail

# 変数
DB_INSTANCE_IDENTIFIER="$*"
SUBNET_IDS="subnet-002e32ddce1eeda13 subnet-0728a99802a7c4bd4"
DB_SUBNET_GROUP_NAME=${DB_INSTANCE_IDENTIFIER}-subnet

if [ "$#" -ne 1 ]; then
  echo  "RDSのホスト名を引数に指定してください。"
  exit 1
fi

# 確認メッセージ
read -r -p "${DB_INSTANCE_IDENTIFIER} のサブネットグループを作成します。よろしいですか？ (y/N): " yn
case "$yn" in [yY]*) ;; *) echo "処理を終了します." ; exit ;; esac

# サブネットグループを作成
aws rds create-db-subnet-group \
  --db-subnet-group-name $DB_SUBNET_GROUP_NAME \
  --db-subnet-group-description $DB_SUBNET_GROUP_NAME \
  --subnet-ids $SUBNET_IDS \
  --tags Key=Name,Value=$DB_SUBNET_GROUP_NAME Key=env,Value=dev 2>&1 1>/dev/null
