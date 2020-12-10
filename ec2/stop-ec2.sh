#!/bin/bash
set -euo pipefail


# 変数
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SERVER_ARRAY=("$@")

# 引数チェック
if [ "$#" -eq 0 ]; then
  echo  "1つ以上の引数を指定してください。"
  exit 1
fi

# 確認メッセージ
echo "Region: ${AWS_DEFAULT_REGION}"
echo "HostName:" "${SERVER_ARRAY[@]}"
read -r -p "上記サーバを停止します。よろしいですか？ (y/N): " yn
case "$yn" in [yY]*) ;; *) echo "処理を終了します." ; exit ;; esac

# メイン処理
function main() {

  # . ${SCRIPT_DIR}/lib/common
  . ${SCRIPT_DIR}/lib/ec2

  for server in "${SERVER_ARRAY[@]}"; do
    HOST_NAME=$server
    INSTANCE_STATE_NAME="running"

    echo "${HOST_NAME} の停止を開始します。"

    # インスタンスIDを取得
    INSTANCE_ID=$(get_instance_id_with_state)
    if [ x = x$INSTANCE_ID ]; then
      echo "インスタンスIDの取得に失敗しました。処理を終了します"
      exit 1
    fi

    # EC2インスタンスを停止
    stop_ec2

    echo "${HOST_NAME} の停止が終了しました。"
  done

}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
