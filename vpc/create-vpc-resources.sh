#!/bin/bash
set -euo pipefail

### 変数一覧 ###

# 共通
export AWS_DEFAULT_REGION="ap-northeast-1"
ENVIRONMENT="Dev"
PREFIX="awscli"

# VPC
VPC_NAME="${PREFIX}-vpc"
VPC_CIDR_BLOCK="10.100.0.0/16"

# パブリックサブネット
declare -A PUBLIC_SUBNET_1A=(
  [name]=${VPC_NAME}-public-subnet-1a
  [cidr]=10.100.11.0/24
  [az]=${AWS_DEFAULT_REGION}a
)

declare -A PUBLIC_SUBNET_1C=(
  [name]=${VPC_NAME}-public-subnet-1c
  [cidr]=10.100.12.0/24
  [az]=${AWS_DEFAULT_REGION}c
)

# プライベートサブネット
declare -A PRIVATE_SUBNET_1A=(
  [name]=${VPC_NAME}-private-subnet-1a
  [cidr]=10.100.21.0/24
  [az]=${AWS_DEFAULT_REGION}a
)

declare -A PRIVATE_SUBNET_1C=(
  [name]=${VPC_NAME}-private-subnet-1c
  [cidr]=10.100.22.0/24
  [az]=${AWS_DEFAULT_REGION}c
)

### 関数一覧 ###

# VPCを作成
function func_create_vpc () {
  aws ec2 create-vpc \
    --cidr-block "$1" \
    --instance-tenancy default
}

# サブネットを作成
function func_create_subnet () {
  aws ec2  create-subnet \
    --vpc-id "$1" \
    --cidr-block "$2" \
    --availability-zone "$3"
}

# ルートテーブルを作成
function func_create_route_table () {
  aws ec2 create-route-table \
    --vpc-id "$1"
}

# ルートテーブルにインターネットゲートウェイ宛のルートを作成
function func_create_route_to_igw () {
  aws ec2 create-route \
    --route-table-id "$1" \
    --destination-cidr-block 0.0.0.0/0 \
    --gateway-id "$2"
}

# ルートテーブルをサブネットに関連付け
function func_associate_route_table () {
  aws ec2 associate-route-table \
    --route-table-id "$1" \
    --subnet-id "$2"
}

# ACLの情報を取得
function func_describe_network_acl_association () {
  aws ec2 describe-network-acls --filters "Name=vpc-id,Values=$1"
}

# ACLにアウトバウンドのルールを追加
function func_create_network_acl_entry_egress () {
  aws ec2 create-network-acl-entry \
    --network-acl-id "$1" \
    --rule-number "$2" \
    --protocol "$3" \
    --cidr-block "$4" \
    --rule-action "$5" \
    --egress
}

# ACLにインバウンドのルールを追加
function func_create_network_acl_entry_ingress () {
  aws ec2 create-network-acl-entry \
    --network-acl-id "$1" \
    --rule-number "$2" \
    --protocol "$3" \
    --cidr-block "$4" \
    --rule-action "$5" \
    --ingress
}

# ACLを別のサブネットに関連付け
function func_replace_network_acl_association () {
  aws ec2 replace-network-acl-association \
    --network-acl-id "$1" \
    --association-id "$2"
}

### メイン処理 ###

function main() {

  # VPCを作成
  VPC_ID=$(func_create_vpc "$VPC_CIDR_BLOCK" | jq '.Vpc.VpcId' -r)

  # インターネットゲートウェイを作成してVPCにアタッチ
  INTERNET_GATEWAY_ID=$(aws ec2 create-internet-gateway | jq '.InternetGateway.InternetGatewayId' -r)
  aws ec2 attach-internet-gateway --internet-gateway-id "$INTERNET_GATEWAY_ID" --vpc-id "$VPC_ID"

  # サブネットを作成
  PUBLIC_SUBNET_1A_ID=$(func_create_subnet "$VPC_ID" "${PUBLIC_SUBNET_1A[cidr]}" "${PUBLIC_SUBNET_1A[az]}" | jq '.Subnet.SubnetId' -r)
  PUBLIC_SUBNET_1C_ID=$(func_create_subnet "$VPC_ID" "${PUBLIC_SUBNET_1C[cidr]}" "${PUBLIC_SUBNET_1C[az]}" | jq '.Subnet.SubnetId' -r)
  PRIVATE_SUBNET_1A_ID=$(func_create_subnet "$VPC_ID" "${PRIVATE_SUBNET_1A[cidr]}" "${PRIVATE_SUBNET_1A[az]}" | jq '.Subnet.SubnetId' -r)
  PRIVATE_SUBNET_1C_ID=$(func_create_subnet "$VPC_ID" "${PRIVATE_SUBNET_1C[cidr]}" "${PRIVATE_SUBNET_1C[az]}" | jq '.Subnet.SubnetId' -r)

  # ルートテーブルを作成
  PUBLIC_ROUTE_TABLE_ID=$(func_create_route_table "$VPC_ID" | jq '.RouteTable.RouteTableId' -r)
  PRIVATE_ROUTE_TABLE_ID=$(func_create_route_table "$VPC_ID" | jq '.RouteTable.RouteTableId' -r)

  # パブリックルートテーブルにインターネットゲートウェイ宛のルートを作成
  func_create_route_to_igw "$PUBLIC_ROUTE_TABLE_ID" "$INTERNET_GATEWAY_ID"

  # ルートテーブルをサブネットに関連付け
  func_associate_route_table "$PUBLIC_ROUTE_TABLE_ID" "$PUBLIC_SUBNET_1A_ID"
  func_associate_route_table "$PUBLIC_ROUTE_TABLE_ID" "$PUBLIC_SUBNET_1C_ID"
  func_associate_route_table "$PRIVATE_ROUTE_TABLE_ID" "$PRIVATE_SUBNET_1A_ID"
  func_associate_route_table "$PRIVATE_ROUTE_TABLE_ID" "$PRIVATE_SUBNET_1C_ID"

  # デフォルトで作成されるACLの関連付けIDを取得
  PUBLIC_SUBNET_1A_ASSOCIATION_ID=$(func_describe_network_acl_association "$VPC_ID" | jq '.NetworkAcls[].Associations[] | select(.SubnetId == "'$PUBLIC_SUBNET_1A_ID'").NetworkAclAssociationId' -r)
  PUBLIC_SUBNET_1C_ASSOCIATION_ID=$(func_describe_network_acl_association "$VPC_ID" | jq '.NetworkAcls[].Associations[] | select(.SubnetId == "'$PUBLIC_SUBNET_1C_ID'").NetworkAclAssociationId' -r)
  PRIVATE_SUBNET_1A_ASSOCIATION_ID=$(func_describe_network_acl_association "$VPC_ID" | jq '.NetworkAcls[].Associations[] | select(.SubnetId == "'$PRIVATE_SUBNET_1A_ID'").NetworkAclAssociationId' -r)
  PRIVATE_SUBNET_1C_ASSOCIATION_ID=$(func_describe_network_acl_association "$VPC_ID" | jq '.NetworkAcls[].Associations[] | select(.SubnetId == "'$PRIVATE_SUBNET_1C_ID'").NetworkAclAssociationId' -r)

  # ACLを作成
  PUBLIC_SUBNET_ACL_ID=$(aws ec2 create-network-acl --vpc-id "$VPC_ID" | jq '.NetworkAcl.NetworkAclId' -r)
  PRIVATE_SUBNET_ACL_ID=$(aws ec2 create-network-acl --vpc-id "$VPC_ID" | jq '.NetworkAcl.NetworkAclId' -r)

  # ACLにすべて許可のルールを追加
  func_create_network_acl_entry_egress "$PUBLIC_SUBNET_ACL_ID" 100 -1 0.0.0.0/0 allow
  func_create_network_acl_entry_ingress "$PUBLIC_SUBNET_ACL_ID" 100 -1 0.0.0.0/0 allow
  func_create_network_acl_entry_egress "$PRIVATE_SUBNET_ACL_ID" 100 -1 0.0.0.0/0 allow
  func_create_network_acl_entry_ingress "$PRIVATE_SUBNET_ACL_ID" 100 -1 0.0.0.0/0 allow

  # ACLをサブネットに関連付け
  func_replace_network_acl_association "$PUBLIC_SUBNET_ACL_ID" "$PUBLIC_SUBNET_1A_ASSOCIATION_ID"
  func_replace_network_acl_association "$PUBLIC_SUBNET_ACL_ID" "$PUBLIC_SUBNET_1C_ASSOCIATION_ID"
  func_replace_network_acl_association "$PRIVATE_SUBNET_ACL_ID" "$PRIVATE_SUBNET_1A_ASSOCIATION_ID"
  func_replace_network_acl_association "$PRIVATE_SUBNET_ACL_ID" "$PRIVATE_SUBNET_1C_ASSOCIATION_ID"

  # タグ付与
  aws ec2 create-tags --resources "$VPC_ID" --tags Key=Name,Value=$VPC_NAME Key=Env,Value=$ENVIRONMENT
  aws ec2 create-tags --resources "$INTERNET_GATEWAY_ID" --tags Key=Name,Value=${VPC_NAME}-igw Key=Env,Value="$ENVIRONMENT"
  aws ec2 create-tags --resources "$PUBLIC_SUBNET_1A_ID" --tags Key=Name,Value="${PUBLIC_SUBNET_1A[name]}" Key=Env,Value="$ENVIRONMENT"
  aws ec2 create-tags --resources "$PUBLIC_SUBNET_1C_ID" --tags Key=Name,Value="${PUBLIC_SUBNET_1C[name]}" Key=Env,Value="$ENVIRONMENT"
  aws ec2 create-tags --resources "$PRIVATE_SUBNET_1A_ID" --tags Key=Name,Value="${PRIVATE_SUBNET_1A[name]}" Key=Env,Value="$ENVIRONMENT"
  aws ec2 create-tags --resources "$PRIVATE_SUBNET_1C_ID" --tags Key=Name,Value="${PRIVATE_SUBNET_1C[name]}" Key=Env,Value="$ENVIRONMENT"
  aws ec2 create-tags --resources "$PUBLIC_ROUTE_TABLE_ID" --tags Key=Name,Value=${VPC_NAME}-public-rt Key=Env,Value="$ENVIRONMENT"
  aws ec2 create-tags --resources "$PRIVATE_ROUTE_TABLE_ID" --tags Key=Name,Value=${VPC_NAME}-private-rt Key=Env,Value="$ENVIRONMENT"
  aws ec2 create-tags --resources "$PUBLIC_SUBNET_ACL_ID" --tags Key=Name,Value=${VPC_NAME}-public-acl Key=Env,Value="$ENVIRONMENT"
  aws ec2 create-tags --resources "$PRIVATE_SUBNET_ACL_ID" --tags Key=Name,Value=${VPC_NAME}-private-acl Key=Env,Value="$ENVIRONMENT"

}

# 他のスクリプトファイルからsourceで呼ばれた場合は実行しない
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
