#!/bin/bash
set -eo pipefail

# 変数
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SECURITY_GROUP_NAME="$1"
PROTOCOL="$2"
PORT="$3"
CIDR="$4"

# 引数チェック
if [ "$#" -ne 4 ]; then
  echo "第1引数にセキュリティグループ名、第2引数にプロトコル、第3引数にポート番号、第4引数にCIDRを指定してください。"
  exit 1
fi

# 確認メッセージ
echo "Region:${AWS_DEFAULT_REGION}"
read -r -p "セキュリティグループにインバウンドルールを追加します。よろしいですか？ (y/N): " yn
case "$yn" in [yY]*) ;; *) echo "処理を終了します." ; exit ;; esac

# メイン処理
function main() {

# . ${SCRIPT_DIR}/lib/common
. ${SCRIPT_DIR}/lib/ec2

echo "${SECURITY_GROUP_NAME} にルール追加を開始しました。"

# セキュリティグループIDを取得
SECURITY_GROUP_ID=$(get_security_group_id_by_name_tag)

# セキュリティグループにインバウンドルールを追加
create_security_group_ingress_rule_by_cidr

echo "${SECURITY_GROUP_NAME} にルール追加を終了しました。"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
