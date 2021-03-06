#!/bin/bash
set -eo pipefail

# 変数
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REGION="$1"
FLAG="$2"

# 引数チェック
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

  . ${SCRIPT_DIR}/lib/common
  . ${SCRIPT_DIR}/lib/rds

  for i in "${SERVER_ARRAY[@]}"; do

    # 変数に格納
    DB_INSTANCE_IDENTIFIER=$(echo $i | cut -d , -f 1)
    NEW_DB_INSTANCE_IDENTIFIER=${DB_INSTANCE_IDENTIFIER}-renamed

    echo "---${DB_INSTANCE_IDENTIFIER} --> ${NEW_DB_INSTANCE_IDENTIFIER} start---"

    # DBインスタンスの名前を変更
    rename_db_instance_name

    echo "---${DB_INSTANCE_IDENTIFIER} end---"

  done

}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
