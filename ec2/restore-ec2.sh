#!/bin/bash
set -euo pipefail

# 変数
SERVER_FILE="restore-list.csv"
IAMROLE_PREFIX="IAMROLE_"
TENANCY="default" # "default"|"dedicated"|"host"

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

  case $OS in
    RHEL) USER_DATA="dr-rhel.sh" ;;
    Windows) USER_DATA="dr-windows.ps1" ;;
  esac

  # 最新のAMIを取得
  LATEST_AMI_ID=$(aws ec2 describe-images --owner self --filter "Name=tag:Name,Values=$HOST_NAME*" --query "sort_by(Images, &CreationDate)[-1].ImageId" --output text)

  # ネットワークインターフェイスIDを取得
  NETWORK_INTERFACE_ID=$(aws ec2 describe-network-interfaces --filters Name=addresses.private-ip-address,Values=$PRIVATE_IP --query "NetworkInterfaces[].NetworkInterfaceId" --output text)

  # EC2インスタンスを作成
  echo "${HOST_NAME} の作成を開始しました。"

  INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $LATEST_AMI_ID \
    --count 1 \
    --instance-type $INSTANCE_TYPE \
    --key-name "my-key-pair" \
    --network-interfaces NetworkInterfaceId=${NETWORK_INTERFACE_ID},DeviceIndex=0 \
    --iam-instance-profile Name=${IAMROLE_PREFIX}${HOST_NAME} \
    --user-data fileb://userdata/${USER_DATA} \
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
