#!/bin/bash
set -euo pipefail

# 変数
DB_INSTANCE_IDENTIFIER="$*"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
SUBSCRIPTION_NAME=${DB_INSTANCE_IDENTIFIER}-alert
SNS_TOPIC_NAME="MyTopic"
SNS_TOPIC_ARN="arn:aws:sns:${AWS_DEFAULT_REGION}:${ACCOUNT_ID}:${SNS_TOPIC_NAME}"

if [ "$#" -ne 1 ]; then
  echo  "RDSのホスト名を引数に指定してください。"
  exit 1
fi

# 確認メッセージ
read -r -p "${DB_INSTANCE_IDENTIFIER} のイベントサブスクリプションを作成します。よろしいですか？ (y/N): " yn
case "$yn" in [yY]*) ;; *) echo "処理を終了します." ; exit ;; esac

# イベントサブスクリプションを作成

aws rds create-event-subscription \
  --subscription-name $SUBSCRIPTION_NAME \
  --sns-topic-arn $SNS_TOPIC_ARN \
  --source-type db-instance \
  --event-categories '["failover","notification","maintenance","failure"]' \
  --source-ids $DB_INSTANCE_IDENTIFIER
  --enabled \
  --tags Key=Name,Value=$DB_INSTANCE_IDENTIFIER Key=evn,Value=dev
