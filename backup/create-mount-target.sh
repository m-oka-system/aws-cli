#!/bin/bash
set -e

# Common Variables
servers=$(cat efs-list.csv | sed 1d)
createdEfs=($(cat CreatedEfsList))

echo "${servers[@]}"
read -p "EFSにマウントターゲットを追加します。よろしいですか？ (y/N): " yn
case "$yn" in [yY]*) ;; *) echo "処理を終了します." ; exit ;; esac

# Main
n=0
for i in ${servers[@]}; do
  # Variables
  region=$(echo $i | cut -d , -f 1)
  efsName=$(echo $i | cut -d , -f 3)
  subnetId1=$(echo $i | cut -d , -f 4)
  subnetId2=$(echo $i | cut -d , -f 5)
  privateIp1=$(echo $i | cut -d , -f 6)
  privateIp2=$(echo $i | cut -d , -f 7)
  securityGroupId=$(echo $i | cut -d , -f 8)
  latestRecoveryPoint=$(echo ${createdEfs[$n]} | cut -d , -f 2)
  restoreJobId=$(echo ${createdEfs[$n]} | cut -d , -f 3)
  createdEfsName=${efsName}-restored
  subnetIds=($subnetId1 $subnetId2)
  efsIpAddresses=($privateIp1 $privateIp2)

  echo "---$efsName create mount target start---"
  # Creates a mount target for a created EFS.
  createdEfsId=$(aws backup describe-restore-job --region $region --restore-job-id $restoreJobId --query CreatedResourceArn --output text | awk -F/ '{print $2}')
  if [ x = x$createdEfsId ]; then
    echo "${efsName} のEFSID取得に失敗しました。リストア処理が完了していません。処理をスキップします。"
    n=$((n + 1))
    continue
  fi

  mountTargets=$(aws efs describe-mount-targets --region $region --file-system-id $createdEfsId --query "length(MountTargets)" --output text)
  if [ $mountTargets -gt 0 ]; then
    echo "${efsName} のマウントターゲットはすでに登録されています。処理をスキップします。"
    n=$((n + 1))
    continue
  fi

  for ((j=0; j < ${#subnetIds[*]}; j++)); do
    NetworkInterfaceId=$(aws efs create-mount-target --region $region --file-system-id $createdEfsId --subnet-id ${subnetIds[$j]} --ip-address ${efsIpAddresses[$j]} --security-groups $securityGroupId --query NetworkInterfaceId --output text)
    NetworkInterfaceIds[$j]=$NetworkInterfaceId
  done

  # Get tags of latest recovery point
  echo "---Copy tags to EFS and ENI from latest recovery point"
  latestRecoveryPointTags=($(aws backup list-tags --region $region --resource-arn $latestRecoveryPoint --query Tags --output yaml | sed -e's/ //g'))
  for k in ${latestRecoveryPointTags[@]}; do
    key=$(echo $k | cut -d : -f 1)
    value=$(echo $k | cut -d : -f 2)
    aws efs tag-resource --region $region --resource-id $createdEfsId --tags Key=$key,Value=$value
    aws ec2 create-tags --region $region --resources ${NetworkInterfaceIds[@]} --tags Key=$key,Value=$value
  done

  # Overwrite name tag
  echo "---Overwrite name tag of EFS and ENI"
  aws efs tag-resource --region $region --resource-id $createdEfsId --tags Key=Name,Value=$createdEfsName
  aws ec2 create-tags --region $region --resources ${NetworkInterfaceIds[@]} --tags Key=Name,Value=${createdEfsName}_ENI

  n=$((n + 1))
  echo "---$efsName create mount target finished---"
done
