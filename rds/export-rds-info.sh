#!/bin/bash
set -eo pipefail

# 変数
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EXPORT_DIR=${SCRIPT_DIR}/export
mkdir -p $EXPORT_DIR
REGION="$1"
DB_INSTANCE_IDENTIFIER="$2"

# 引数チェック
if [ "$#" -ne 2 ]; then
  echo "第1引数にリージョン、第2引数にDB識別子を指定してください"
  exit 1
fi

if [[ "$REGION" != "ap-northeast-1" && "$REGION" != "ap-southeast-1" ]]; then
  echo "第1引数にはap-northeast-1,ap-southeast-1のいずれかを指定してください。"
  exit 1
fi

function main() {

  . ${SCRIPT_DIR}/lib/common
  . ${SCRIPT_DIR}/lib/rds

  echo "---${DB_INSTANCE_IDENTIFIER} start---"

  get_db_instance > ${EXPORT_DIR}/${DB_INSTANCE_IDENTIFIER}.json

  DB_INSTANCE_ARN=$(get_db_instance_arn)
  list_db_instance_tags > ${EXPORT_DIR}/${DB_INSTANCE_IDENTIFIER}_tags.json

  echo "---${DB_INSTANCE_IDENTIFIER} end---"

}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
