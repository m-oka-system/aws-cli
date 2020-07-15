#!/usr/bin/env bash

set -e

function create-efs-from-backup () {

efsId=$(aws efs describe-file-systems --region $region --query "FileSystems[?Name==\`$efsName\`].FileSystemId" --output text)
if [ -z "$efsId" ]; then
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

latestRecoveryPoints+=($latestRecoveryPoint)
restoreJobIds+=($restoreJobId)

}


