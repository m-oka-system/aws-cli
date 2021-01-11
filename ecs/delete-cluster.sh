#!/bin/bash
set -euo pipefail

# 変数
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLUSTER_NAME="rails-cluster"

# 確認メッセージ
echo "Region:${AWS_DEFAULT_REGION}"
echo "CLUSTER_NAME:$CLUSTER_NAME"
read -r -p "上記ECSクラスターを削除します。よろしいですか？ (y/N): " yn
case "$yn" in [yY]*) ;; *) echo "処理を終了します." ; exit ;; esac

# メイン処理
function main() {

  . ${SCRIPT_DIR}/lib/ecs

  aws ecs delete-cluster --cluster $CLUSTER_NAME

}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
