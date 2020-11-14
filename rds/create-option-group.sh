#!/bin/bash
set -euo pipefail

# 変数
DB_INSTANCE_IDENTIFIER="$*"
DB_ENGINE_NAME="mysql"
MAJOR_ENGINE_VERSION="8.0"
DB_OPTION_GROUP_NAME=${DB_INSTANCE_IDENTIFIER}-option-group

if [ "$#" -ne 1 ]; then
  echo  "RDSのホスト名を引数に指定してください。"
  exit 1
fi

# 確認メッセージ
read -r -p "${DB_INSTANCE_IDENTIFIER} のオプショングループを作成します。よろしいですか？ (y/N): " yn
case "$yn" in [yY]*) ;; *) echo "処理を終了します." ; exit ;; esac

# オプショングループを作成
aws rds create-option-group \
  --option-group-name $DB_OPTION_GROUP_NAME \
  --engine-name $DB_ENGINE_NAME \
  --major-engine-version $MAJOR_ENGINE_VERSION \
  --option-group-description $DB_OPTION_GROUP_NAME \
  --tags Key=Name,Value=$DB_OPTION_GROUP_NAME Key=env,Value=dev
