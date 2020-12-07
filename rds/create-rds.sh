#!/bin/bash
set -euo pipefail

# 変数
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SERVER_FILE="db-list.csv"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# サーバ一覧のファイルを1行ずつ読み込んで配列へ格納
mapfile -t SERVER_ARRAY < <(sed 1d ${SCRIPT_DIR}/${SERVER_FILE} | sed '/^#/d')

# 確認メッセージ
for array in "${SERVER_ARRAY[@]}"; do echo $array; done
read -r -p "上記サーバを作成します。よろしいですか？ (y/N): " yn
case "$yn" in [yY]*) ;; *) echo "処理を終了します." ; exit ;; esac

function main() {

  . ${SCRIPT_DIR}/lib/get_datetime
  . ${SCRIPT_DIR}/lib/create_db_instance_single_az

  for i in "${SERVER_ARRAY[@]}"; do
    # 変数に格納
    DB_INSTANCE_IDENTIFIER=$(echo $i | cut -d , -f 1)
    DB_INSTANCE_CLASS=$(echo $i | cut -d , -f 2)
    VPC_SECURITY_GROUP_NAME=$(echo $i | cut -d , -f 3)
    STORAGE_TYPE=$(echo $i | cut -d , -f 4)
    ALLOCATED_STORAGE=$(echo $i | cut -d , -f 5)
    DB_ENGINE=$(echo $i | cut -d , -f 6)
    DB_ENGINE_VERSION=$(echo $i | cut -d , -f 7)
    PORT=$(echo $i | cut -d , -f 8)
    DB_NAME=$(echo $i | cut -d , -f 9)
    DB_USER_NAME=$(echo $i | cut -d , -f 10)
    DB_USER_PASSWORD=$(echo $i | cut -d , -f 11)
    MULTI_AZ=$(echo $i | cut -d , -f 12)

    case "$DB_ENGINE" in
      sqlserver*)
        LOGS_EXPORTS='"error"'
        LICENSE_MODEL="license-included"
      ;;
      mysql)
        LOGS_EXPORTS='"error","general","slowquery"'
        LICENSE_MODEL="general-public-license"
      ;;
      oracle*)
        LOGS_EXPORTS='"error","general","audit","slowquery"'
        LICENSE_MODEL="license-included"
      ;;
    esac

    # Create RDS instances
    echo "---${DB_INSTANCE_IDENTIFIER} start---"

    if [ "$MULTI_AZ" = "true" ]; then
      create_db_instance_multi_az
    else
      create_db_instance_single_az
    fi

    echo "---${DB_INSTANCE_IDENTIFIER} end---"

  done

}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi

