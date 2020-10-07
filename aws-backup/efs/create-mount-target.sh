#!/bin/bash
set -euo pipefail

# 変数
SERVER_FILE="efs-list.csv"
CREATED_EFS_FILE="CreatedEfsList"

# ファイルを1行ずつ読み込んで配列へ格納
mapfile -t SERVER_ARRAY < <(sed 1d $SERVER_FILE | sed '/^#/d')
mapfile -t CREATED_EFS < <(cat $CREATED_EFS_FILE)

echo "${SERVER_ARRAY[@]}"
read -rp "EFSにマウントターゲットを追加します。よろしいですか？ (y/N): " yn
case "$yn" in [yY]*) ;; *) echo "処理を終了します." ; exit ;; esac

# Main
n=0
for i in "${SERVER_ARRAY[@]}"; do
  # Variables
  REGION=$(echo $i | cut -d , -f 1)
  EFS_NAME=$(echo $i | cut -d , -f 3)
  SUBNET_ID1=$(echo $i | cut -d , -f 5)
  SUBNET_ID2=$(echo $i | cut -d , -f 6)
  PRIVATE_IP1=$(echo $i | cut -d , -f 7)
  PRIVATE_IP2=$(echo $i | cut -d , -f 8)
  SECURITY_GROUP_ID=$(echo $i | cut -d , -f 9)
  LATEST_RECOVERY_POINT=$(echo ${CREATED_EFS[$n]} | cut -d , -f 2)
  RESTORE_JOB_ID=$(echo ${CREATED_EFS[$n]} | cut -d , -f 3)
  CREATED_EFS_NAME=${EFS_NAME}-restored
  SUBNET_IDS=("$SUBNET_ID1" "$SUBNET_ID2")
  EFS_IP_ADDRESSES=("$PRIVATE_IP1" "$PRIVATE_IP2")

  echo "$EFS_NAME のマウントターゲット作成を開始します。"
  # リストアしたEFSのIDを取得
  CREATED_EFS_ID=$(aws backup describe-restore-job --region $REGION --restore-job-id $RESTORE_JOB_ID --query CreatedResourceArn --output text | awk -F/ '{print $2}')
  if [ x = x$CREATED_EFS_ID ]; then
    echo "${EFS_NAME} のEFSID取得に失敗しました。リストア処理が完了していません。処理をスキップします。"
    n=$((n + 1))
    continue
  fi

  # マウントターゲットが存在する場合は処理を終了
  MOUNT_TARGETS=$(aws efs describe-mount-targets --region $REGION --file-system-id $CREATED_EFS_ID --query "length(MountTargets)" --output text)
  if [ $MOUNT_TARGETS -gt 0 ]; then
    echo "${EFS_NAME} のマウントターゲットはすでに登録されています。処理をスキップします。"
    n=$((n + 1))
    continue
  fi

  # マウントターゲットを作成(ENIのIDは配列へ格納)
  declare -a NETWORK_INTERFACE_IDS=()
  for ((j=0; j < ${#SUBNET_IDS[*]}; j++)); do
    NETWORK_INTERFACE_ID=$(aws efs create-mount-target --region $REGION --file-system-id $CREATED_EFS_ID --subnet-id ${SUBNET_IDS[$j]} --ip-address ${EFS_IP_ADDRESSES[$j]} --security-groups $SECURITY_GROUP_ID --query NetworkInterfaceId --output text)
    NETWORK_INTERFACE_IDS[$j]=$NETWORK_INTERFACE_ID
  done

  # 最新の復旧ポイントのタグを取得
  echo "---最新の復旧ポイントのタグをEFS、ENIにコピーします。"
  # LATEST_RECOVERY_POINT_TAGS=($(aws backup list-tags --region $REGION --resource-arn $LATEST_RECOVERY_POINT --query Tags --output yaml | sed -e's/ //g'))
  # mapfile -t LATEST_RECOVERY_POINT_TAGS < <(aws backup list-tags --region $REGION --resource-arn $LATEST_RECOVERY_POINT --query "Tags" --output yaml | sed -e 's/ //g')
  mapfile -t LATEST_RECOVERY_POINT_TAGS < <(aws backup list-tags --region $REGION --resource-arn $LATEST_RECOVERY_POINT --query "Tags" --output json | sed -e '1d' -e '$d' -e 's/ //g' -e 's/"//g' -e 's/,$//g') #json出力から1行目、最終行、スペース、ダブルクォーテーション、末尾のカンマを除外

  if [ ${#LATEST_RECOVERY_POINT_TAGS[*]} -eq 0 ]; then
    echo "${EFS_NAME} の復旧ポイントにはタグが存在しません。処理をスキップします。"
  else
    for k in "${LATEST_RECOVERY_POINT_TAGS[@]}"; do
      KEY=$(echo $k | cut -d : -f 1)
      VALUE=$(echo $k | cut -d : -f 2)
      aws efs tag-resource --region $REGION --resource-id $CREATED_EFS_ID --tags Key=$KEY,Value=$VALUE
      aws ec2 create-tags --region $REGION --resources "${NETWORK_INTERFACE_IDS[@]}" --tags Key=$KEY,Value=$VALUE
    done

    # Nameタグを上書き
    echo "---EFSとENIのNameタグを上書きします。"
    aws efs tag-resource --region $REGION --resource-id $CREATED_EFS_ID --tags Key=Name,Value=$CREATED_EFS_NAME
    aws ec2 create-tags --region $REGION --resources "${NETWORK_INTERFACE_IDS[@]}" --tags Key=Name,Value=${CREATED_EFS_NAME}_ENI
  fi

  n=$((n + 1))
  echo "$EFS_NAME のマウントターゲット作成が終了しました。"
done
