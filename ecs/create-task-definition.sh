#!/bin/bash
set -euo pipefail

# 変数
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TASK_DEF_DIR="tasks"
TASK_DEF_JSON_FILE="fargate-task.json"

# 確認メッセージ
echo "Region:${AWS_DEFAULT_REGION}"
read -r -p "タスク定義を作成します。よろしいですか？ (y/N): " yn
case "$yn" in [yY]*) ;; *) echo "処理を終了します." ; exit ;; esac

# メイン処理
function main() {

  . ${SCRIPT_DIR}/lib/ecs

  mkdir -p $TASK_DEF_DIR
  aws ecs register-task-definition --cli-input-json file://$TASK_DEF_DIR/${TASK_DEF_JSON_FILE}

}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
