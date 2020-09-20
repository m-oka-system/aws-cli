#!/bin/bash
set -euo pipefail

# 変数
SERVER_ARRAY=("$@")

if [ "$#" -eq 0 ]; then
  echo  "1つ以上のホスト名を引数を指定してください。"
  exit 1
fi

# メイン処理
for server in "${SERVER_ARRAY[@]}"; do
  HOST_NAME=$server

  # IAMロールを作成
  aws iam create-role \
    --role-name IAMROLE_${HOST_NAME} \
    --assume-role-policy-document file://policy/AssumeRole.json

  # インスタンスプロファイルを作成
  aws iam create-instance-profile \
    --instance-profile-name IAMROLE_${HOST_NAME}

  # インスタンスプロファイルにIAMロールを追加
  aws iam add-role-to-instance-profile \
    --role-name IAMROLE_${HOST_NAME} \
    --instance-profile-name IAMROLE_${HOST_NAME}
done
