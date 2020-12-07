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
read -r -p "上記サーバを作成します。よろしいですか？ (y/N): " yn
case "$yn" in [yY]*) ;; *) echo "処理を終了します." ; exit ;; esac

function main() {

  . ${SCRIPT_DIR}/lib/common
  . ${SCRIPT_DIR}/lib/rds

  # 共通変数
  ACCOUNT_ID=$(get_account_id)

  for i in "${SERVER_ARRAY[@]}"; do
    # 変数に格納
    DB_INSTANCE_IDENTIFIER=$(echo $i | cut -d , -f 1)
    DB_INSTANCE_CLASS=$(echo $i | cut -d , -f 2)
    VPC_SECURITY_GROUP_NAME=$(echo $i | cut -d , -f 3)
    DB_ENGINE=$(echo $i | cut -d , -f 4)
    MULTI_AZ=$(echo $i | cut -d , -f 5)
    NEW_DB_INSTANCE_IDENTIFIER=${DB_INSTANCE_IDENTIFIER}-renamed

    case "$DB_ENGINE" in
      sqlserver*) LOGS_EXPORTS='"error"' ;;
      mysql) LOGS_EXPORTS='"error","general","slowquery"' ;;
      oracle*) LOGS_EXPORTS='"error","general","audit","slowquery"' ;;
    esac

    echo "---${DB_INSTANCE_IDENTIFIER} start---"

    # 最新のスナップショットを取得
    LATEST_DB_SNAPSHOT_ARN=$(get_latest_db_snapshot)

    # DBインスタンスをリストア
    case "$FLAG" in
      "dr")
        case "$MULTI_AZ" in
          "true") restore_db_instance_multi ;;
          "false") restore_db_instance_single ;;
        esac
      ;;
      "az") restore_db_instance_single_to_point_in_time ;;
    esac

    # 拡張モニタリングを有効化
    enable_enhanced_monitoring

    # パフォーマンスインサイトを有効化
    enable_performance_insight

  done

  echo "---${DB_INSTANCE_IDENTIFIER} end---"

}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
