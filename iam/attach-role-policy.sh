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
POLICY_NAMES=("IAMPOLICY_EC2_RUN_USERDATA" "IAMPOLICY_SSM_RUN_COMMAND")
SSM_POLICY_ARN="arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"

# メイン処理
for server in "${SERVER_ARRAY[@]}"; do
  HOST_NAME=$server

  # IAMロールに指定したポリシーをアタッチする
  for policy in "${POLICY_NAMES[@]}"; do
    POLICY_ARN="arn:aws:iam::${ACCOUNT_ID}:policy/${policy}"
    aws iam attach-role-policy --policy-arn $POLICY_ARN --role-name ${IAMROLE_PREFIX}${HOST_NAME}
  done

  # IAMロールにSSMのポリシーをアタッチする（マネージドインスタンス化に必要）
  # aws iam attach-role-policy --policy-arn $SSM_POLICY_ARN --role-name ${IAMROLE_PREFIX}${HOST_NAME}
done
