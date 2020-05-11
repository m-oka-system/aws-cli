<powershell>

# ec2 metadata
$AWS_AVAIL_ZONE=(curl http://169.254.169.254/latest/meta-data/placement/availability-zone).Content
$AWS_REGION=$AWS_AVAIL_ZONE.Substring(0,$AWS_AVAIL_ZONE.length-1)
$AWS_INSTANCE_ID=(curl http://169.254.169.254/latest/meta-data/instance-id).Content
$ROOT_VOLUME_IDS=(aws ec2 describe-instances --region $AWS_REGION --instance-id $AWS_INSTANCE_ID --output text --query Reservations[0].Instances[0].BlockDeviceMappings[0].Ebs.VolumeId)
$VOLUME_IDS=(aws ec2 describe-instances --region $AWS_REGION --instance-id $AWS_INSTANCE_ID --output text --query Reservations[0].Instances[0].BlockDeviceMappings[].Ebs.VolumeId) -split "	"
$NETWORK_INTERFACE_IDS=(aws ec2 describe-instances --region $AWS_REGION --instance-id $AWS_INSTANCE_ID --output text --query Reservations[0].Instances[0].NetworkInterfaces[].NetworkInterfaceId)

# variables
$driveLetter=[char[]](67..90) #C..Z
$hostName=(aws ec2 describe-instances --region $AWS_REGION --instance-id $AWS_INSTANCE_ID --output text --query 'Reservations[].Instances[].Tags[?Key==`Name`].Value')

# timezone
Set-TimeZone -id "Tokyo Standard Time"

# hostname
Rename-Computer -NewName $hostName -Force

# Disable firewall
Get-NetFirewallProfile | Set-NetFirewallProfile -Enabled false

# Mount data disk
$disks=Get-Disk | where { ($_.Number -ne 0) -and ($_.OperationalStatus -eq "Offline") }
for ($i = 0; $i -lt @($disks).Length; $i++)
{ 
  $disks[$i] | Initialize-Disk -PartitionStyle MBR -PassThru | `
  New-Partition -UseMaximumSize -DriveLetter $driveLetter[$i+1] | `
  Format-Volume -FileSystem NTFS -NewFileSystemLabel Data -Force
}

# Add tags to ebs volume
for ($i = 0; $i -lt $VOLUME_IDS.Length; $i++)
{ 
  $volumeName= $hostName + "_" + $driveLetter[$i]
  aws ec2 create-tags --resources $VOLUME_IDS[$i] --region $AWS_REGION --tags Key=Name,Value=$volumeName
}
# aws ec2 create-tags --resources $ROOT_VOLUME_IDS --region $AWS_REGION --tags Key=Name,Value=$hostName"_ROOT"

# Add tags to network interface
aws ec2 create-tags --resources $NETWORK_INTERFACE_IDS --region $AWS_REGION --tags Key=Name,Value=$hostName"_ENI"

# Restart computer
Restart-Computer -Force
</powershell>