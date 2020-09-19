#!/bin/bash
set -euo pipefail

# 変数
export AWS_DEFAULT_REGION="ap-northeast-1"
DOMAIN_NAME="example.local"
VPC_ID="vpc-08ad5c00c7cdece78"

# ホストゾーンに変更前のファイルをインポート
echo "${DOMAIN_NAME} の作成を開始します。"
cli53 create --vpc-id "$VPC_ID" --vpc-region "$AWS_DEFAULT_REGION" "$DOMAIN_NAME"
echo "${DOMAIN_NAME} の作成が終了しました。"
