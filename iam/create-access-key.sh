#!/bin/bash
set -euo pipefail

# 変数
USER_NAME="$1"

# メイン処理
ACCESS_KEY=$(aws iam create-access-key --user-name $USER_NAME --query "AccessKey.[AccessKeyId,SecretAccessKey]" --output text)

ACCESS_KEY_ID=$(echo ${ACCESS_KEY} | cut -f 1)
SECRET_ACCESS_KEY=$(echo ${ACCESS_KEY} | cut -f 2)

aws configure set aws_access_key_id $ACCESS_KEY_ID --profile $USER_NAME
aws configure set aws_secret_access_key $SECRET_ACCESS_KEY --profile $USER_NAME
