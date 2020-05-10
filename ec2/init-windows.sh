<powershell>

# variables
$AWS_AVAIL_ZONE=(curl http://169.254.169.254/latest/meta-data/placement/availability-zone).Content
$AWS_REGION=$AWS_AVAIL_ZONE.Substring(0,$AWS_AVAIL_ZONE.length-1)
$AWS_INSTANCE_ID=(curl http://169.254.169.254/latest/meta-data/instance-id).Content
$ROOT_VOLUME_IDS=(aws ec2 describe-instances --region $AWS_REGION --instance-id $AWS_INSTANCE_ID --output text --query Reservations[0].Instances[0].BlockDeviceMappings[0].Ebs.VolumeId)
$DATA_VOLUME_IDS=(aws ec2 describe-instances --region $AWS_REGION --instance-id $AWS_INSTANCE_ID --output text --query Reservations[0].Instances[0].BlockDeviceMappings[].Ebs.VolumeId)
$NETWORK_INTERFACE_IDS=(aws ec2 describe-instances --region $AWS_REGION --instance-id $AWS_INSTANCE_ID --output text --query Reservations[0].Instances[0].NetworkInterfaces[].NetworkInterfaceId)

# timezone
Set-TimeZone -id "Tokyo Standard Time"

# hostname
$hostName=(aws ec2 describe-instances --region $AWS_REGION --instance-id $AWS_INSTANCE_ID --output text --query 'Reservations[].Instances[].Tags[?Key==`Name`].Value')
Rename-Computer -NewName $hostName -Force

# Disable firewall
Get-NetFirewallProfile | Set-NetFirewallProfile -Enabled false

# Add tags to ebs volume and network interface
aws ec2 create-tags --resources $DATA_VOLUME_IDS --region $AWS_REGION --tags Key=Name,Value=$hostName"_DATA"
aws ec2 create-tags --resources $ROOT_VOLUME_IDS --region $AWS_REGION --tags Key=Name,Value=$hostName"_ROOT"
aws ec2 create-tags --resources $NETWORK_INTERFACE_IDS --region $AWS_REGION --tags Key=Name,Value=$hostName"_ENI"

# restart computer
Restart-Computer -Force
</powershell>