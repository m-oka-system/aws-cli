#!/bin/bash
set -eo pipefail

# 変数
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VPC_ID="$1"
SECURITY_GROUP_NAME="$2"

# 引数チェック
if [ "$#" -ne 2 ]; then
  echo "第1引数にVPCID、第2引数にセキュリティグループ名を指定してください。"
  exit 1
fi

# 確認メッセージ
echo "Region:${AWS_DEFAULT_REGION}"
read -r -p "セキュリティグループを作成します。よろしいですか？ (y/N): " yn
case "$yn" in [yY]*) ;; *) echo "処理を終了します." ; exit ;; esac

# メイン処理
function main() {

# . ${SCRIPT_DIR}/lib/common
. ${SCRIPT_DIR}/lib/ec2

echo "${SECURITY_GROUP_NAME} の作成を開始しました。"

# セキュリティグループを作成
SECURITY_GROUP_ID=$(create_security_group)
aws ec2 create-tags --resources $SECURITY_GROUP_ID --tags Key=Name,Value=${SECURITY_GROUP_NAME} 2>&1 1>/dev/null

echo "${SECURITY_GROUP_NAME} の作成が終了しました。"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
