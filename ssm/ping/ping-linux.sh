#!/bin/bash

# 変数
SCRIPT_DIR=$(dirname "$0")
SERVER_FILE="hosts-linux"

# サーバ一覧のファイルを1行ずつ読み込んで配列へ格納
mapfile -t SERVER_ARRAY < <(cat $SCRIPT_DIR/$SERVER_FILE)

# メイン処理
echo "---ping start---"

for server in "${SERVER_ARRAY[@]}"; do
  ping -c 1 $server >/dev/null
  if [ "$?" = 0 ]; then
    echo "${server}:success"
  else
    echo "${server}:failed"
    exit 1
  fi
done

echo "---ping end---"
