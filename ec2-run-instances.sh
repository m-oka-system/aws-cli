region=""
latestAmi=$(aws ec2 describe-images --owner self --filter Name=tag-key,Values=env,Name=tag-value,Values=dev --query "sort_by(Images, &CreationDate)[-1].ImageId" --output text)
instanceType=""
keyName=""
subnetId=""
privateIP=""
securityGroupId=""

aws ec2 run-instances --region $region \
  --image-id $latestAmi \
  --count 1 \
  --instance-type $instanceType \
  --key-name $keyName \
  --subnet-id $subnetId \
  --private-ip-address $privateIP \
  --security-group-ids $securityGroupId \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=ServerName},{Key=env,Value=dev}]'