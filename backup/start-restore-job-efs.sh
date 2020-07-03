#!/bin/bash

region="ap-northeast-1"
efsId="fs-6a3f3d4b"
vaultName="jpn-efs-backup-vault"
latestRecoveryPoint=$(aws backup list-recovery-points-by-backup-vault --region $region --backup-vault-name $vaultName --query "sort_by(RecoveryPoints, &CreationDate)[-1].RecoveryPointArn" --output text)
iamRoleArn="arn:aws:iam::$ACCOUNT_ID:role/service-role/AWSBackupDefaultServiceRole"
token=$(uuidgen)

# Restore EFS from AWS Backup recovery points
restoreJobId=$(aws backup start-restore-job --region $region \
  --recovery-point-arn $latestRecoveryPoint \
  --iam-role-arn $iamRoleArn\
  --resource-type EFS \
  --metadata file-system-id=$efsId,newFileSystem=true,CreationToken=$token,Encrypted=false,PerformanceMode=generalPurpose \
  --output text)

# Wait until the EFS restore is complete
i=1
while [ $i -le 30 ]
do
  status=$(aws backup describe-restore-job --region $region --restore-job-id $restoreJobId --query Status --output text)
  if [ $status = "COMPLETED" ]; then
    echo "$(date +%Y-%m-%d):EFSのリストアが完了しました。"
    break
  fi

  echo "$(date +%Y-%m-%d):EFSのリストア完了まで待機します。"
  sleep 1m
  i=$((i + 1))
done

# Creates a mount target for a created EFS.
# createdEfsId=$(aws efs describe-file-systems --region $region --query "sort_by(FileSystems, &CreationTime)[-1].FileSystemId" --output text) && echo restoredEfsId
createdEfsId=$(aws backup describe-restore-job --region $region --restore-job-id $restoreJobId --query CreatedResourceArn --output text | awk -F/ '{print $2}')
createdEfsName="EFS01-restored"
subnetId1="subnet-05cee398d8071777b"
subnetId2="subnet-0253f67cb0e6f5068"
efsIpAddress1="10.0.11.200"
efsIpAddress2="10.0.21.200"
securityGroupId="sg-0d940172c4a4c6585"
aws efs create-mount-target --region $region --file-system-id $createdEfsId --subnet-id $subnetId1 --ip-address $efsIpAddress1 --security-groups $securityGroupId
aws efs create-mount-target --region $region --file-system-id $createdEfsId --subnet-id $subnetId2 --ip-address $efsIpAddress2 --security-groups $securityGroupId
aws efs tag-resource --region $region --resource-id $createdEfsId --tags Key=Name,Value=$createdEfsName
