#!/bin/bash
set -euo pipefail

# 変数
SERVER_FILE="server-list.csv"
IAMROLE_PREFIX="IAMROLE_"
TENANCY="default" # "default"|"dedicated"|"host"
KEY_NAME="my-key-pair"

# サーバ一覧のファイルを1行ずつ読み込んで配列へ格納
mapfile -t SERVER_ARRAY < <(sed 1d $SERVER_FILE | sed '/^#/d')

# 確認メッセージ
echo "Region:${AWS_DEFAULT_REGION}"
for array in "${SERVER_ARRAY[@]}"; do echo $array; done
read -r -p "上記サーバを作成します。よろしいですか？ (y/N): " yn
case "$yn" in [yY]*) ;; *) echo "処理を終了します." ; exit ;; esac

# メイン処理
for server in "${SERVER_ARRAY[@]}"; do
  # Variables
  AMI_ID=$(echo $server | cut -d , -f 1)
  HOST_NAME=$(echo $server | cut -d , -f 2)
  ENVIRONMENT=$(echo $server | cut -d , -f 3)
  OS=$(echo $server | cut -d , -f 4)
  INSTANCE_TYPE=$(echo $server | cut -d , -f 5)
  PRIVATE_IP=$(echo $server | cut -d , -f 6)
  SUBNET_ID=$(echo $server | cut -d , -f 7)
  SECURITY_GROUP_ID=$(echo $server | cut -d , -f 8)
  # test $OS == "Linux" && USER_DATA="init-linux.sh" || USER_DATA="init-windows.ps1"
  case $OS in
    RHEL) USER_DATA="init-rhel.sh" ;;
    Amazon) USER_DATA="init-amazon.sh" ;;
    Windows) USER_DATA="init-windows.ps1" ;;
  esac

  # EC2インスタンスを作成
  echo "${HOST_NAME} の作成を開始しました。"

  INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --count 1 \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME \
    --subnet-id $SUBNET_ID \
    --private-ip-address $PRIVATE_IP \
    --security-group-ids $SECURITY_GROUP_ID \
    --block-device-mappings file://volume/${HOST_NAME}.json \
    --iam-instance-profile Name=${IAMROLE_PREFIX}${HOST_NAME} \
    --user-data file://userdata/${USER_DATA} \
    --disable-api-termination \
    --placement Tenancy=${TENANCY} \
    --capacity-reservation-specification CapacityReservationPreference=none \
    --query "Instances[].InstanceId" --output text)

  # タグ付与
  sleep 1
  ROOT_VOLUME_ID=$(aws ec2 describe-instances --instance-id $INSTANCE_ID --query Reservations[0].Instances[0].BlockDeviceMappings[0].Ebs.VolumeId --output text)
  VOLUME_IDS=$(aws ec2 describe-instances --instance-id $INSTANCE_ID --query Reservations[0].Instances[0].BlockDeviceMappings[].Ebs.VolumeId --output text)
  NETWORK_INTERFACE_IDS=$(aws ec2 describe-instances --instance-id $INSTANCE_ID --query Reservations[0].Instances[0].NetworkInterfaces[].NetworkInterfaceId --output text)

  {
  aws ec2 create-tags --resources $INSTANCE_ID --tags Key=Name,Value=$HOST_NAME Key=Env,Value=$ENVIRONMENT
  aws ec2 create-tags --resources $VOLUME_IDS --tags Key=Name,Value=${HOST_NAME}_DATA
  aws ec2 create-tags --resources $ROOT_VOLUME_ID --tags Key=Name,Value=${HOST_NAME}_ROOT
  aws ec2 create-tags --resources $NETWORK_INTERFACE_IDS --tags Key=Name,Value=${HOST_NAME}_ENI
  } 2>&1 1>/dev/null

  echo "${HOST_NAME} の作成が終了しました。"
done
