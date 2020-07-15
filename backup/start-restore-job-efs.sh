#!/bin/bash
set -e

# Common Variables
servers=$(cat efs-list.csv | sed 1d)
iamRoleArn="arn:aws:iam::$ACCOUNT_ID:role/service-role/AWSBackupDefaultServiceRole"
sourceRegion="ap-northeast-1"
token=$(uuidgen)
maxSleepSecs=30
sleepInterval="1m"

echo "${servers[@]}"
read -p "EFSのリストアを開始します。よろしいですか？ (y/N): " yn
case "$yn" in [yY]*) ;; *) echo "処理を終了します." ; exit ;; esac

# Initialize created efs list
: > CreatedEfsList

# Main
for i in ${servers[@]}; do
  # Variables
  region=$(echo $i | cut -d , -f 1)
  vaultName=$(echo $i | cut -d , -f 2)
  efsName=$(echo $i | cut -d , -f 3)

  echo "---$efsName restore start---"
  # Get efs id from source region
  efsId=$(aws efs describe-file-systems --region $sourceRegion --query "FileSystems[?Name==\`$efsName\`].FileSystemId" --output text)
  if [ x = x$efsId ]; then
    echo "EFSIDの取得に失敗しました。処理を終了します。"
  fi

  # Restore EFS from AWS Backup recovery points
  latestRecoveryPoint=$(aws backup list-recovery-points-by-backup-vault --region $region --backup-vault-name $vaultName --query "sort_by(RecoveryPoints, &CreationDate)[?contains(ResourceArn,\`$efsId\`)]|[-1].RecoveryPointArn" --output text)
  restoreJobId=$(aws backup start-restore-job --region $region \
    --recovery-point-arn $latestRecoveryPoint \
    --iam-role-arn $iamRoleArn\
    --resource-type EFS \
    --metadata file-system-id=$efsId,newFileSystem=true,CreationToken=$token,Encrypted=false,PerformanceMode=generalPurpose \
    --output text)

  echo "${efsName},${latestRecoveryPoint},${restoreJobId}" >> CreatedEfsList
  echo "---$efsName restore finished---"
done

echo "EFSリストアのステータスはコンソール画面から確認してください。"
echo "EFSリストア完了後、マウントターゲットの追加を行ってください。"
