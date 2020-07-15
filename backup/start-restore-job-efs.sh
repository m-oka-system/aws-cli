#!/bin/bash
set -e

# Common Variables
servers=$(cat efs-list.csv | sed 1d)
iamRoleArn="arn:aws:iam::834829755694:role/service-role/AWSBackupDefaultServiceRole"
# iamRoleArn="arn:aws:iam::$ACCOUNT_ID:role/service-role/AWSBackupDefaultServiceRole"
sourceRegion="ap-northeast-1"
token=$(uuidgen)
# token="2d709a85-a552-4db6-8b71-21284c4c02fd"
maxSleepSecs=30
sleepInterval="1m"

# Import functions
cwd="$(cd "$(dirname "$0")" && pwd)"
. ./lib/create-efs-from-backup.sh
. ./lib/wait-efs-restore-complete.sh

# echo "${servers[@]}"
# read -p "EFSのリストアを開始します。よろしいですか？ (y/N): " yn
# case "$yn" in [yY]*) ;; *) echo "処理を終了します." ; exit ;; esac

for i in ${servers[@]}; do
  # Variables
  region=$(echo $i | cut -d , -f 1)
  vaultName=$(echo $i | cut -d , -f 2)
  efsName=$(echo $i | cut -d , -f 3)

  echo "===$efsName start==="
  create-efs-from-backup
  wait-efs-restore-complete $restoreJobId &
  pids+=($!)
  sleep 1
done

echo "$(date +%Y-%m-%d_%H-%M-%S):EFSのリストア完了まで待機します(タイムアウト:${maxSleepSecs}分)"
jobs -l
for pid in ${pids[@]}; do
  wait $pid
  if [ $? -ne 0 ]; then
    echo "EFSリストアがタイムアウトになったため処理を終了します。"
    jobs=`jobs -p`
    if [ -n "$jobs" ]; then
      kill -9 $jobs
    fi
    exit 1
  fi
done

read -p "待機します..."

n=0
for i in ${servers[@]}; do
# Variables
  region=$(echo $i | cut -d , -f 1)
  subnetId1=$(echo $i | cut -d , -f 4)
  subnetId2=$(echo $i | cut -d , -f 5)
  privateIp1=$(echo $i | cut -d , -f 6)
  privateIp2=$(echo $i | cut -d , -f 7)
  securityGroupId=$(echo $i | cut -d , -f 8)
  createdEfsName=${efsName}-restored
  subnetIds=($subnetId1 $subnetId2)
  efsIpAddresses=($privateIp1 $privateIp2)

  # Creates a mount target for a created EFS.
  createdEfsId=$(aws backup describe-restore-job --region $region --restore-job-id ${restoreJobIds[$n]} --query CreatedResourceArn --output text | awk -F/ '{print $2}')

  for ((j=0; j < ${#subnetIds[*]}; j++)); do
    NetworkInterfaceId=$(aws efs create-mount-target --region $region --file-system-id $createdEfsId --subnet-id ${subnetIds[$j]} --ip-address ${efsIpAddresses[$j]} --security-groups $securityGroupId --query NetworkInterfaceId --output text)
    NetworkInterfaceIds[$j]=$NetworkInterfaceId
  done

  # Get tags of latest recovery point
  latestRecoveryPointTags=($(aws backup list-tags --region $region --resource-arn ${latestRecoveryPoints[$n]} --output yaml | sed -e's/ //g' -e 1d))
  for ((k=0; k < ${#latestRecoveryPointTags[*]}; k++)); do
    key=$(echo ${latestRecoveryPointTags[$k]} | cut -d : -f 1)
    value=$(echo ${latestRecoveryPointTags[$k]} | cut -d : -f 2)
    aws efs tag-resource --region $region --resource-id $createdEfsId --tags Key=$key,Value=$value
    aws ec2 create-tags --region $region --resources ${NetworkInterfaceIds[@]} --tags Key=$key,Value=$value
  done

  # Overwrite name tag
  aws efs tag-resource --region $region --resource-id $createdEfsId --tags Key=Name,Value=$createdEfsName
  aws ec2 create-tags --region $region --resources ${NetworkInterfaceIds[@]} --tags Key=Name,Value=${createdEfsName}_ENI

  n=$((n + 1))
  echo "===$efsName finished==="
done
