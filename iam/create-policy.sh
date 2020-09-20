#!/bin/bash
set -euo pipefail

# 変数
POLICY_NAME="$*"
IAMPOLICY_PREFIX="IAMPOLICY_"

if [ "$#" -ne 1 ]; then
  echo  "IAMポリシーの名前を引数に指定してください。"
  exit 1
fi

# IAMポリシーを作成
IAMPOLICY_ARN=$(aws iam create-policy \
  --policy-name ${IAMPOLICY_PREFIX}${POLICY_NAME} \
  --policy-document file://policy/${POLICY_NAME}.json \
  --output text --query "Policy.Arn")

echo $IAMPOLICY_ARN
