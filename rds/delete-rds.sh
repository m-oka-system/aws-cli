#!/bin/bash
set -eo pipefail

# 変数
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REGION="$1"
DB_INSTANCE_IDENTIFIER_ARRAY=(${@:2})

# 引数チェック
if [[ "$REGION" != "ap-northeast-1" && "$REGION" != "ap-southeast-1" ]]; then
  echo "第1引数にはap-northeast-1,ap-southeast-1のいずれかを指定してください。"
  exit 1
fi

function main() {

  . ${SCRIPT_DIR}/lib/common
  . ${SCRIPT_DIR}/lib/rds

  for DB_INSTANCE_IDENTIFIER in "${DB_INSTANCE_IDENTIFIER_ARRAY[@]}"; do

    echo "---${DB_INSTANCE_IDENTIFIER} start---"

    disable_delete_protection
    delete_db_instance

    echo "---${DB_INSTANCE_IDENTIFIER} end---"

  done

}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
