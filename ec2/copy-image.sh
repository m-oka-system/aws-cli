#!/bin/bash
set -eo pipefail

# 変数
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOST_NAME="$1"
DST_REGION="$2"
NOW_DATE=`date +%Y-%m-%d-%H-%M-%S`
COPIED_IMAGE_NAME=${HOST_NAME}-${NOW_DATE}

# 引数チェック
if [ "$#" -ne 2 ]; then
  echo "第1引数にホスト名、第2引数にコピー先リージョンを指定してください"
  exit 1
fi

# 確認メッセージ
echo "Source region: ${AWS_DEFAULT_REGION}"
echo "Destination region: ${AWS_DEFAULT_REGION}"
echo "HostName:" "${HOST_NAME}"
read -r -p "上記サーバのAMIをコピーします。よろしいですか？ (y/N): " yn
case "$yn" in [yY]*) ;; *) echo "処理を終了します." ; exit ;; esac

# メイン処理
function main() {

  # . ${SCRIPT_DIR}/lib/common
  . ${SCRIPT_DIR}/lib/ec2

  echo "${HOST_NAME} のAMIコピーを開始します。"

  LATEST_AMI_ID=$(get_latest_ami_id)
  if [ x = x$LATEST_AMI_ID ]; then
    echo "AMI IDの取得に失敗しました。処理を終了します"
    exit 1
  fi

  LATEST_AMI_TAG_KEYS=($(get_ami_tag_keys $LATEST_AMI_ID))
  LATEST_AMI_TAG_VALUES=($(get_ami_tag_values $LATEST_AMI_ID))

  # AMIを指定したリージョンにコピー
  COPIED_IMAGE_ID=$(copy_image)

  # コピーしたAMIにタグをコピー
  for ((i=0; i < ${#LATEST_AMI_TAG_KEYS[*]}; i++)); do
    aws ec2 create-tags --region $DST_REGION --resources $COPIED_IMAGE_ID --tags Key=${LATEST_AMI_TAG_KEYS[$i]},Value=${LATEST_AMI_TAG_VALUES[$i]}
  done

  echo "${HOST_NAME} のAMIコピーが終了しました。AMI ID:${COPIED_IMAGE_ID}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
