#!/bin/bash
set -e

# Common Variables
servers=$(cat efs-list.csv | sed 1d)
iamRoleArn="arn:aws:iam::$ACCOUNT_ID:role/service-role/AWSBackupDefaultServiceRole"
# token=$(uuidgen)
token="637d0d03-d839-4961-b970-66dfc8b0c057"
maxSleepSecs=1
sleepInterval="1m"

# Import functions
cwd="$(cd "$(dirname "$0")" && pwd)"
. ./lib/create-efs-from-backup.sh
. ./lib/wait-efs-restore-complete.sh

echo "${servers[@]}"
read -p "EFSのリストアを開始します。よろしいですか？ (y/N): " yn
case "$yn" in [yY]*) ;; *) echo "処理を終了します." ; exit ;; esac

for i in ${servers[@]}; do
  region=$(echo $i | cut -d , -f 1)
  vaultName=$(echo $i | cut -d , -f 2)
  efsName=$(echo $i | cut -d , -f 3)

  subnetId1=$(echo $i | cut -d , -f 4)
  subnetId2=$(echo $i | cut -d , -f 5)
  privateIp1=$(echo $i | cut -d , -f 6)
  privateIp2=$(echo $i | cut -d , -f 7)
  securityGroupId=$(echo $i | cut -d , -f 8)


  create-efs-from-backup
  wait-efs-restore-complete $restoreJobId &
done

wait
read -p "待機します..."

# Creates a mount target for a created EFS.
# createdEfsId=$(aws efs describe-file-systems --region $region --query "sort_by(FileSystems, &CreationTime)[-1].FileSystemId" --output text) && echo restoredEfsId
createdEfsId=$(aws backup describe-restore-job --region $region --restore-job-id $restoreJobId --query CreatedResourceArn --output text | awk -F/ '{print $2}')
createdEfsName=${efsName}-restored
subnetIds=($subnetId1 $subnetId2)
efsIpAddresses=($privateIp1 $privateIp2)
latestRecoveryPointTags=$(aws backup list-tags --resource-arn $latestRecoveryPoint)

for ((i=0; i < ${#subnetIds[*]}; i++)); do
  NetworkInterfaceId=$(aws efs create-mount-target --region $region --file-system-id $createdEfsId --subnet-id ${subnetIds[$i]} --ip-address ${efsIpAddresses[$i]} --security-groups $securityGroupId)
  NetworkInterfaceIds[$i]=$NetworkInterfaceId
done

# Add tags
aws efs tag-resource --region $region --resource-id $createdEfsId --tags Key=Name,Value=$createdEfsName
aws ec2 create-tags --resources ${NetworkInterfaceIds[@]} --tags Key=Name,Value=${createdEfsName}_ENI
