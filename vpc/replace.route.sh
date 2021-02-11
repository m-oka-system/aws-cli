#!/bin/bash
set -euo pipefail

# 変数
# SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_REGION="$1"
REGION="ap-northeast-1"
ROUTE_TABLE_ID="rtb-xxxxxxxxxx"
DEST_CIDR_BLOCK="10.0.0.0/16"
NETWORK_INTERFACE_ID="eni-xxxxxxxxxx"
# TRANSIT_GATEWAY_ID="tgw-xxxxxxxxxx"
INTERNET_GATEWAY_ID="igw-xxxxxxxxxx"

# 関数
function replace_route_to_eni () {
  aws ec2 replace-route --region $REGION \
    --route-table-id $1 \
    --destination-cidr-block $2 \
    --network-interface-id $NETWORK_INTERFACE_ID
}

function replace_route_to_tgw () {
  aws ec2 replace-route --region $REGION \
    --route-table-id $1 \
    --destination-cidr-block $2 \
    --gateway-id $INTERNET_GATEWAY_ID
    # --transit-gateway-id $TRANSIT_GATEWAY_ID
}

function get_route_table () {
  aws ec2 describe-route-tables --region $REGION \
    --route-table-ids $1 \
    --query "RouteTables[].Routes[?DestinationCidrBlock==\`$2\`][]" \
    --output table
}

# 確認メッセージ
read -r -p "ルートテーブルのターゲットを変更します。よろしいですか？ (y/N): " yn
case "$yn" in [yY]*) ;; *) echo "処理を終了します." ; exit ;; esac

# メイン処理
case "$TARGET_REGION" in
  ap-northeast-1)
    replace_route_to_tgw $ROUTE_TABLE_ID $DEST_CIDR_BLOCK
    get_route_table $ROUTE_TABLE_ID $DEST_CIDR_BLOCK
  ;;
  ap-southeast-1)
    replace_route_to_eni $ROUTE_TABLE_ID $DEST_CIDR_BLOCK
    get_route_table $ROUTE_TABLE_ID $DEST_CIDR_BLOCK
  ;;
esac
