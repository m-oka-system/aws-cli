#!/bin/bash
set -euo pipefail

# 変数
SERVER_FILE="efs-list.csv"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
IAMROLE_ARN="arn:aws:iam::$ACCOUNT_ID:role/service-role/AWSBackupDefaultServiceRole"
TOKEN=$(uuidgen)

# サーバ一覧のファイルを1行ずつ読み込んで配列へ格納
mapfile -t SERVER_ARRAY < <(sed 1d $SERVER_FILE | sed '/^#/d')

echo "${SERVER_ARRAY[@]}"
read -rp "EFSのリストアを開始します。よろしいですか？ (y/N): " yn
case "$yn" in [yY]*) ;; *) echo "処理を終了します." ; exit ;; esac

# リストア済みEFSリストを初期化
: > CreatedEfsList

# メイン処理
for i in "${SERVER_ARRAY[@]}"; do
  # Variables
  REGION=$(echo $i | cut -d , -f 1)
  VAULT_NAME=$(echo $i | cut -d , -f 2)
  EFS_NAME=$(echo $i | cut -d , -f 3)
  SOURCE_EFS_ID=$(echo $i | cut -d , -f 4)

  echo "$EFS_NAME のリストアを開始しました。"

  # AWSBackupの最新の復旧ポイントからEFSをリストア
  LATEST_RECOVERY_POINT=$(aws backup list-recovery-points-by-backup-vault --region $REGION --backup-vault-name $VAULT_NAME --query "sort_by(RecoveryPoints, &CreationDate)[?contains(ResourceArn,\`$SOURCE_EFS_ID\`)]|[-1].RecoveryPointArn" --output text)
  if [ x = x$LATEST_RECOVERY_POINT ]; then
    echo "復旧ポイントの取得に失敗しました。処理を終了します。"
    exit 1
  fi

  echo "LatestRecoveryPointArn:${LATEST_RECOVERY_POINT}"
  read -rp "上記復旧ポイントからリストアします。よろしいですか？ (y/N): " yn
  case "$yn" in [yY]*) ;; *) echo "処理を終了します." ; exit ;; esac

  RESTORE_JOB_ID=$(aws backup start-restore-job --region $REGION \
    --recovery-point-arn $LATEST_RECOVERY_POINT \
    --iam-role-arn $IAMROLE_ARN \
    --resource-type EFS \
    --metadata file-system-id=$SOURCE_EFS_ID,newFileSystem=true,CreationToken=$TOKEN,Encrypted=false,PerformanceMode=generalPurpose \
    --output text)

  echo "${EFS_NAME},${LATEST_RECOVERY_POINT},${RESTORE_JOB_ID}" >> CreatedEfsList
  echo "---$EFS_NAME restore finished---"
done

echo "EFSリストアのステータスはコンソール画面から確認してください。"
echo "EFSリストア完了後、マウントターゲットの追加を行ってください。"
