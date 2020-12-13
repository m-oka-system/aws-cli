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
read -r -p "上記サーバのAMIを作成します。よろしいですか？ (y/N): " yn
case "$yn" in [yY]*) ;; *) echo "処理を終了します." ; exit ;; esac

# メイン処理
function main() {

  # . ${SCRIPT_DIR}/lib/common
  . ${SCRIPT_DIR}/lib/ec2

  for server in "${SERVER_ARRAY[@]}"; do
    HOST_NAME=$server
    NOW_DATE=`date +%Y-%m-%d-%H-%M-%S`
    IMAGE_NAME=${HOST_NAME}-${NOW_DATE}

    echo "${HOST_NAME} の取得を開始します。"

    # インスタンスIDを取得
    INSTANCE_ID=$(get_instance_id)
    if [ x = x$INSTANCE_ID ]; then
      echo "インスタンスIDの取得に失敗しました。処理を終了します"
      exit 1
    fi

    # AMIの作成
    IMAGE_ID=$(create_image)

    # Tag付与
    aws ec2 create-tags --resources $IMAGE_ID --tags Key=Name,Value=${IMAGE_NAME}

    echo "${HOST_NAME} の作成が終了しました。AMI ID:${IMAGE_ID}"
  done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
