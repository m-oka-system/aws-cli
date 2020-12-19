#!/bin/bash
set -eo pipefail

# 変数
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOST_NAME="$1"
PRIVATE_IP="$2"
SUBNET_ID="$3"
SECURITY_GROUP_IDS=$(echo "$@" | awk '{for (i = 4; i <= NF; i++) print $i;}')

# 引数チェック
if [ "$#" -lt 4 ]; then
  echo "第1引数にホスト名、第2引数にプライベートIPアドレス、第3引数にサブネットID、第4引数以降にセキュリティグループIDを指定してください。"
  exit 1
fi

# 確認メッセージ
echo "Region:${AWS_DEFAULT_REGION}"
read -r -p "${HOST_NAME}のENIを作成します。よろしいですか？ (y/N): " yn
case "$yn" in [yY]*) ;; *) echo "処理を終了します." ; exit ;; esac

# メイン処理
function main() {

# . ${SCRIPT_DIR}/lib/common
. ${SCRIPT_DIR}/lib/ec2

echo "${HOST_NAME} の作成を開始しました。"

# ネットワークインターフェイスを作成
NETWORK_INTERFACE_ID=$(create_network_interface)
aws ec2 create-tags --resources $NETWORK_INTERFACE_ID --tags Key=Name,Value=${HOST_NAME}_ENI 2>&1 1>/dev/null

echo "${HOST_NAME} の作成が終了しました。"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
