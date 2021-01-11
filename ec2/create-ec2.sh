#!/bin/bash
set -euo pipefail

# 変数
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SERVER_FILE="server-list.csv"
IAM_INSTANCE_PROFILE="IAMROLE_EC2_INSTANCES"
TENANCY="default" # "default"|"dedicated"|"host"
KEY_NAME="my-key-pair"

# サーバ一覧のファイルを1行ずつ読み込んで配列へ格納
mapfile -t SERVER_ARRAY < <(sed 1d ${SCRIPT_DIR}/$SERVER_FILE | sed '/^#/d')

# 確認メッセージ
echo "Region:${AWS_DEFAULT_REGION}"
for array in "${SERVER_ARRAY[@]}"; do echo $array; done
read -r -p "上記サーバを作成します。よろしいですか？ (y/N): " yn
case "$yn" in [yY]*) ;; *) echo "処理を終了します." ; exit ;; esac

# メイン処理
function main() {

  # . ${SCRIPT_DIR}/lib/common
  . ${SCRIPT_DIR}/lib/ec2

  for server in "${SERVER_ARRAY[@]}"; do
    # Variables
    AMI_ID=$(echo $server | cut -d , -f 1)
    HOST_NAME=$(echo $server | cut -d , -f 2)
    ENVIRONMENT=$(echo $server | cut -d , -f 3)
    OS=$(echo $server | cut -d , -f 4)
    INSTANCE_TYPE=$(echo $server | cut -d , -f 5)
    PRIVATE_IP=$(echo $server | cut -d , -f 6)
    SUBNET_ID=$(echo $server | cut -d , -f 7)
    SECURITY_GROUP_IDS=$(echo $server | awk -F, '{for (i = 8; i <= NF; i++) print $i;}')

    case $OS in
      RHEL*|CentOS*) USER_DATA="init-rhel.sh" ;;
      UBUNTU*) USER_DATA="init-ubuntu.sh" ;;
      Amazon*) USER_DATA="init-amazon.sh" ;;
      Windows*) USER_DATA="init-windows.ps1" ;;
    esac

    # ネットワークインターフェイスIDを取得
    NETWORK_INTERFACE_ID=$(get_network_interface_id_by_private_ip)

    # ネットワークインターフェイスが存在しなければ新規作成
    if [ -z "$NETWORK_INTERFACE_ID" ]; then
      NETWORK_INTERFACE_ID=$(create_network_interface)
      aws ec2 create-tags --resources $NETWORK_INTERFACE_ID --tags Key=Name,Value=${HOST_NAME}_ENI
    fi

    # EC2インスタンスを作成
    echo "${HOST_NAME} の作成を開始しました。"

    INSTANCE_ID=$(create_ec2)

    # タグ付与
    sleep 1
    ROOT_VOLUME_ID=$(get_root_volume_id)
    VOLUME_IDS=$(get_volume_ids)

    {
    aws ec2 create-tags --resources $INSTANCE_ID --tags Key=Name,Value=$HOST_NAME Key=Env,Value=$ENVIRONMENT Key=OS,Value=$OS
    aws ec2 create-tags --resources $VOLUME_IDS --tags Key=Name,Value=${HOST_NAME}_DATA
    aws ec2 create-tags --resources $ROOT_VOLUME_ID --tags Key=Name,Value=${HOST_NAME}_ROOT
    } 2>&1 1>/dev/null

    echo "${HOST_NAME} の作成が終了しました。"
  done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
