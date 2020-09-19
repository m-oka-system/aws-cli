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

# 確認メッセージ
echo "$DOMAIN_NAME"
read -r -p "上記ホストゾーンを削除します。よろしいですか？ (y/N): " yn
case "$yn" in [yY]*) ;; *) echo "処理を終了します." ; exit ;; esac

# リソースレコードを全て削除
echo "${DOMAIN_NAME} のリソースレコードの削除を開始します。"
cli53 rrpurge "$ZONE_ID" --confirm
echo "${DOMAIN_NAME} のリソースレコードの削除が終了しました。"

# ホストゾーンを削除
echo "${DOMAIN_NAME} の削除を開始します。"
cli53 delete "$ZONE_ID"
echo "${DOMAIN_NAME} の削除が終了しました。"
