#!/bin/bash

# 変数
REGION="$1"
OS="$2"

# 引数チェック
if [ "$#" -ne 2 ]; then
  echo "第1引数にリージョン、第2引数にOSを指定してください"
  exit 1
fi

if [[ "$REGION" != "ap-northeast-1" && "$REGION" != "ap-southeast-1" ]]; then
  echo "第1引数にはap-northeast-1,ap-southeast-1のいずれかを指定してください。"
  exit 1
fi

if [[ "$OS" != "Linux" && "$OS" != "Windows" ]]; then
  echo "第2引数にはLinux,Windowsのいずれかを指定してください。"
  exit 1
fi

# S3バケット名を定義
case "$REGION" in
  "ap-northeast-1")
    SCRIPT_BUCKET_NAME="con-ssm-scripts"
    OUTPUT_BUCKET_NAME="con-ssm-logs"
  ;;
  "ap-southeast-1")
    SCRIPT_BUCKET_NAME="con-ssm-scripts"
    OUTPUT_BUCKET_NAME="con-ssm-logs"
  ;;
esac

# 実行するスクリプト名を定義
case "$OS" in
  "Linux") SCRIPT_NAME="ping-linux.sh" ;;
  "Windows") SCRIPT_NAME="ping-windows.ps1" ;;
esac

# AWS-RunRemoteScriptを実行
COMMAND_ID=$(aws ssm send-command \
  --region $REGION \
  --document-name "AWS-RunRemoteScript" \
  --document-version "1" \
  --targets '[{"Key":"resource-groups:Name","Values":["'$OS'"]}]' \
  --parameters '{"sourceType":["S3"],"sourceInfo":["{\"path\":\"https://s3-'${REGION}'.amazonaws.com/'${SCRIPT_BUCKET_NAME}'/ping/\"}"],"commandLine":["'${SCRIPT_NAME}'"],"workingDirectory":[""],"executionTimeout":["3600"]}' \
  --timeout-seconds 600 \
  --max-concurrency "50" \
  --max-errors "0" \
  --output-s3-bucket-name $OUTPUT_BUCKET_NAME \
  --query "Command.CommandId" \
  --output text)

echo "RunCommandの処理を開始しました。処理が終わるまで待機します。"
echo "コマンドID:${COMMAND_ID}"

while [ "$STATUS" != "Success" ]; do
  STATUS=$(aws ssm list-commands --region $REGION --command-id $COMMAND_ID --query "Commands[].Status" --output text)

  if [ "$STATUS" = "Failed" ]; then
    echo "RunCommandの処理が失敗しました。"
    exit 1
  fi

  sleep 5
done

echo "RunCommandの処理が終了しました。"
aws ssm list-command-invocations \
  --region $REGION \
  --command-id $COMMAND_ID \
  --query "CommandInvocations[].[InstanceName,Status]" \
  --output table
