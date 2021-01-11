#!/bin/bash
set -euo pipefail

# 変数
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLUSTER_NAME="rails-cluster"
SERVICE_NAME="rails-service"

# 確認メッセージ
echo "Region:${AWS_DEFAULT_REGION}"
echo $SERVICE_NAME
read -r -p "上記サービスを削除します。よろしいですか？ (y/N): " yn
case "$yn" in [yY]*) ;; *) echo "処理を終了します." ; exit ;; esac

# メイン処理
function main() {

  . ${SCRIPT_DIR}/lib/ecs

  aws ecs delete-service \
    --cluster $CLUSTER_NAME \
    --service $SERVICE_NAME \
    --force

}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
