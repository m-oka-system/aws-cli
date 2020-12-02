#!/bin/bash
set -euo pipefail

# 変数
SERVER_ARRAY=("$@")

if [ "$#" -eq 0 ]; then
  echo  "1つ以上の引数を指定してください。"
  exit 1
fi

# 確認メッセージ
echo "Region:${AWS_DEFAULT_REGION}"
echo "HostName:${SERVER_ARRAY[@]}"
read -r -p "上記サーバを削除します。よろしいですか？ (y/N): " yn
case "$yn" in [yY]*) ;; *) echo "処理を終了します." ; exit ;; esac

# メイン処理
for server in "${SERVER_ARRAY[@]}"; do
  HOST_NAME=$server

  echo "${HOST_NAME} の削除を開始します。"

  # インスタンスIDを取得
  INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$HOST_NAME" "Name=instance-state-name,Values=running" --query "Reservations[].Instances[].InstanceId" --output text)
  if [ x = x$INSTANCE_ID ]; then
    echo "インスタンスIDの取得に失敗しました。処理を終了します"
    exit 1
  fi

  # 削除保護を無効化
  aws ec2 modify-instance-attribute --instance-id $INSTANCE_ID --no-disable-api-termination > /dev/null 2>&1

  # EC2インスタンスを削除
  aws ec2 terminate-instances --instance-ids $INSTANCE_ID > /dev/null 2>&1

  echo "${HOST_NAME} の削除が終了しました。"
done
