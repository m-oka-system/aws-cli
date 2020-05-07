#!/bin/bash
servers=$(cat server-list.csv | awk -F, 'NR>1')

for i in ${servers[@]}; do
  # Variables
  region=$(echo $i | cut -d , -f 1)
  amiId=$(echo $i | cut -d , -f 2)
  hostName=$(echo $i | cut -d , -f 3)
  instanceType=$(echo $i | cut -d , -f 4)
  subnetId=$(echo $i | cut -d , -f 5)
  privateIP=$(echo $i | cut -d , -f 6)
  securityGroupId=$(echo $i | cut -d , -f 7)
  rootVolumeSize=$(echo $i | cut -d , -f 8)
  dataVolumeSize=$(echo $i | cut -d , -f 9)
  
  # Create EC2 instances
  aws ec2 run-instances --region $region \
    --image-id $amiId \
    --count 1 \
    --instance-type $instanceType \
    --key-name "my-key-pair" \
    --subnet-id $subnetId \
    --private-ip-address $privateIP \
    --security-group-ids $securityGroupId \
    --block-device-mappings '[{"DeviceName":"/dev/sda1","Ebs":{"VolumeSize":'$rootVolumeSize',"DeleteOnTermination":true,"VolumeType": "gp2"},"DeviceName":"/dev/xvdf","Ebs":{"VolumeSize":'$dataVolumeSize',"DeleteOnTermination":true,"VolumeType": "gp2"}}]' \
    --iam-instance-profile Name="EC2-Role" \
    --user-data file://init.sh \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${hostName}},{Key=env,Value=dev}]"
done