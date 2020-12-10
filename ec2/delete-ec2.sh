#!/bin/bash
set -euo pipefail

# 変数
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SERVER_ARRAY=("$@")

if [ "$#" -eq 0 ]; then
  echo  "1つ以上の引数を指定してください。"
  exit 1
fi

# 確認メッセージ
echo "Region: ${AWS_DEFAULT_REGION}"
echo "HostName:" "${SERVER_ARRAY[@]}"
read -r -p "上記サーバを削除します。よろしいですか？ (y/N): " yn
case "$yn" in [yY]*) ;; *) echo "処理を終了します." ; exit ;; esac

# メイン処理
function main() {

  . ${SCRIPT_DIR}/lib/ec2

  for server in "${SERVER_ARRAY[@]}"; do
    HOST_NAME=$server
    INSTANCE_STATE_NAME="running"

    echo "${HOST_NAME} の削除を開始します。"

    # インスタンスIDを取得
    INSTANCE_ID=$(get_instance_id_with_state)
    if [ x = x$INSTANCE_ID ]; then
      echo "インスタンスIDの取得に失敗しました。処理を終了します"
      exit 1
    fi

    # 削除保護を無効化
    disable_delete_protection

    # EC2インスタンスを削除
    delete_ec2

    echo "${HOST_NAME} の削除が終了しました。"
  done

}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
