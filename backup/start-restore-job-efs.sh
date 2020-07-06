#!/bin/bash
set -e

region="ap-northeast-1"
efsId="fs-6a3f3d4b"
vaultName="jpn-efs-backup-vault"
latestRecoveryPoint=$(aws backup list-recovery-points-by-backup-vault --region $region --backup-vault-name $vaultName --query "sort_by(RecoveryPoints, &CreationDate)[-1].RecoveryPointArn" --output text)
iamRoleArn="arn:aws:iam::$ACCOUNT_ID:role/service-role/AWSBackupDefaultServiceRole"
latestRecoveryPointTags=$(aws backup list-tags --resource-arn $latestRecoveryPoint)
token=$(uuidgen)

# Restore EFS from AWS Backup recovery points
restoreJobId=$(aws backup start-restore-job --region $region \
  --recovery-point-arn $latestRecoveryPoint \
  --iam-role-arn $iamRoleArn\
  --resource-type EFS \
  --metadata file-system-id=$efsId,newFileSystem=true,CreationToken=$token,Encrypted=false,PerformanceMode=generalPurpose \
  --output text)

# Wait until the EFS restore is complete
count=1
while [ $status != "COMPLETED" ]
do
  echo "$(date +%Y-%m-%d_%H-%M-%S):EFSのリストア完了まで待機します。Count:$count"
  sleep 1m
  status=$(aws backup describe-restore-job --region $region --restore-job-id $restoreJobId --query Status --output text)
  if [ $count -gt 60 ]; then
    echo "$(date +%Y-%m-%d_%H-%M-%S):EFSのリストアがタイムアウトしました。処理を終了します。"
    exit 1
  fi
  i=$((i + 1))
done
echo "$(date +%Y-%m-%d_%H-%M-%S):EFSのリストアが完了しました。"

# Creates a mount target for a created EFS.
# createdEfsId=$(aws efs describe-file-systems --region $region --query "sort_by(FileSystems, &CreationTime)[-1].FileSystemId" --output text) && echo restoredEfsId
createdEfsId=$(aws backup describe-restore-job --region $region --restore-job-id $restoreJobId --query CreatedResourceArn --output text | awk -F/ '{print $2}')
createdEfsName="EFS01-restored"
subnetIds=("subnet-05cee398d8071777b" "subnet-0253f67cb0e6f5068")
efsIpAddresses=("10.0.11.200" "10.0.21.200")
securityGroupId="sg-0d940172c4a4c6585"

for ((i=0; i < ${#subnetIds[*]}; i++)); do
  NetworkInterfaceId=$(aws efs create-mount-target --region $region --file-system-id $createdEfsId --subnet-id ${subnetIds[$i]} --ip-address ${efsIpAddresses[$i]} --security-groups $securityGroupId)
  NetworkInterfaceIds[$i]=$NetworkInterfaceId
done

# Add tags
aws efs tag-resource --region $region --resource-id $createdEfsId --tags Key=Name,Value=$createdEfsName
aws ec2 create-tags --resources ${NetworkInterfaceIds[@]} --tags Key=Name,Value=${createdEfsName}_ENI