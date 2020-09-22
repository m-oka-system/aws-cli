#!/bin/bash
set -euo pipefail

# 変数
SERVER_ARRAY=("$@")

if [ "$#" -eq 0 ]; then
  echo  "1つ以上のホスト名を引数を指定してください。"
  exit 1
fi

IAMROLE_PREFIX="IAMROLE_"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
POLICY_NAME="IAMPOLICY_EC2_RUN_USERDATA"
POLICY_ARN="arn:aws:iam::${ACCOUNT_ID}:policy/${POLICY_NAME}"
SSM_POLICY_ARN="arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"

# メイン処理
for server in "${SERVER_ARRAY[@]}"; do
  HOST_NAME=$server

  # IAMロールに指定したポリシーをアタッチする
  aws iam attach-role-policy --policy-arn $POLICY_ARN --role-name ${IAMROLE_PREFIX}${HOST_NAME}

  # IAMロールにSSMのポリシーをアタッチする（マネージドインスタンス化に必要）
  aws iam attach-role-policy --policy-arn $SSM_POLICY_ARN --role-name ${IAMROLE_PREFIX}${HOST_NAME}
done
