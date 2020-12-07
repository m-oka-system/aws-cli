#!/bin/bash
set -eo pipefail

# 関数を定義
function rename_db_instance_name () {
  echo "$(get_datetime) ${FUNCNAME[0]}"
  aws rds modify-db-instance \
    --region $REGION \
    --db-instance-identifier $DB_INSTANCE_IDENTIFIER \
    --new-db-instance-identifier $OLD_DB_INSTANCE_IDENTIFIER \
    --apply-immediately 2>&1 1>/dev/null
}

# 変数
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REGION="$1"
FLAG="$2"

if [ "$#" -ne 2 ]; then
  echo "第1引数にリージョン、第2引数にフラグを指定してください"
  exit 1
fi

if [[ "$REGION" != "ap-northeast-1" && "$REGION" != "ap-southeast-1" ]]; then
  echo "第1引数にはap-northeast-1,ap-southeast-1のいずれかを指定してください。"
  exit 1
fi

if [[ "$FLAG" != "dr" && "$FLAG" != "az" ]]; then
  echo "第1引数にはdr,azのいずれかを指定してください。"
  exit 1
fi

# サーバ一覧のファイルを1行ずつ読み込んで配列へ格納
case "$REGION" in
  ap-northeast-1)
    case "$FLAG" in
      "dr") mapfile -t SERVER_ARRAY < <(sed 1d ${SCRIPT_DIR}/${FLAG}/rds-${REGION}-${FLAG}.csv | sed '/^#/d') ;;
      "az") mapfile -t SERVER_ARRAY < <(sed 1d ${SCRIPT_DIR}/${FLAG}/rds-${REGION}-${FLAG}.csv | sed '/^#/d') ;;
    esac
  ;;
  ap-southeast-1)
    case "$FLAG" in
      "dr") mapfile -t SERVER_ARRAY < <(sed 1d ${SCRIPT_DIR}/${FLAG}/rds-${REGION}-${FLAG}.csv | sed '/^#/d') ;;
      "az") mapfile -t SERVER_ARRAY < <(sed 1d ${SCRIPT_DIR}/${FLAG}/rds-${REGION}-${FLAG}.csv | sed '/^#/d') ;;
    esac
  ;;
esac

# 確認メッセージ
for array in "${SERVER_ARRAY[@]}"; do echo $array; done
read -r -p "上記サーバの名前を変更します。よろしいですか？ (y/N): " yn
case "$yn" in [yY]*) ;; *) echo "処理を終了します." ; exit ;; esac

function main() {

  local cwd
  cwd="$(cd "$(dirname "$0")" && pwd)"
  . ${cwd}/lib/get_datetime

  for i in "${SERVER_ARRAY[@]}"; do

    # 変数に格納
    DB_INSTANCE_IDENTIFIER=$(echo $i | cut -d , -f 1)
    OLD_DB_INSTANCE_IDENTIFIER=${DB_INSTANCE_IDENTIFIER}-old

    echo "---${DB_INSTANCE_IDENTIFIER} --> ${OLD_DB_INSTANCE_IDENTIFIER} start---"

    # Rename db instance name
    rename_db_instance_name

    echo "---${DB_INSTANCE_IDENTIFIER} end---"

  done

}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
