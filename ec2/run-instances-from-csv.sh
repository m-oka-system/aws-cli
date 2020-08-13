#!/bin/bash
servers=$(cat server-list.csv | sed 1d | sed '/^#/d')

for i in ${servers[@]}; do
  # Variables
  region=$(echo $i | cut -d , -f 1)
  amiId=$(echo $i | cut -d , -f 2)
  OS=$(echo $i | cut -d , -f 3)
  hostName=$(echo $i | cut -d , -f 4)
  instanceType=$(echo $i | cut -d , -f 5)
  subnetId=$(echo $i | cut -d , -f 6)
  privateIP=$(echo $i | cut -d , -f 7)
  securityGroupId=$(echo $i | cut -d , -f 8)
  iamRole=$(echo $i | cut -d , -f 9)
  test $OS == "Linux" && userData="init-linux.sh" || userData="init-windows.ps1"

  # Create EC2 instances
  aws ec2 run-instances --region $region \
    --image-id $amiId \
    --count 1 \
    --instance-type $instanceType \
    --key-name "my-key-pair" \
    --subnet-id $subnetId \
    --private-ip-address $privateIP \
    --security-group-ids $securityGroupId \
    --block-device-mappings file://volume/$hostName.json \
    --iam-instance-profile Name=$iamRole \
    --user-data file://userdata/$userData \
    --disable-api-termination \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${hostName}},{Key=env,Value=dev}]" 2>&1 1>/dev/null
done
