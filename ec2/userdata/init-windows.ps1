<powershell>

# ec2 metadata
$AWS_AVAIL_ZONE=(curl http://169.254.169.254/latest/meta-data/placement/availability-zone).Content
$AWS_REGION=$AWS_AVAIL_ZONE.Substring(0,$AWS_AVAIL_ZONE.length-1)
$AWS_INSTANCE_ID=(curl http://169.254.169.254/latest/meta-data/instance-id).Content
$ROOT_VOLUME_IDS=aws ec2 describe-instances --region $AWS_REGION --instance-id $AWS_INSTANCE_ID --output text --query Reservations[0].Instances[0].BlockDeviceMappings[0].Ebs.VolumeId
$VOLUME_IDS=(aws ec2 describe-instances --region $AWS_REGION --instance-id $AWS_INSTANCE_ID --output text --query "sort_by(Reservations[0].Instances[0].BlockDeviceMappings[],&DeviceName)[].Ebs.VolumeId") -split "	"
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
$disks=Get-Disk | sort Number | where { ($_.Number -ne 0) }
for ($i = 0; $i -lt @($disks).Length; $i++)
{ 
  $volumeId=$VOLUME_IDS[$i+1].Replace("-","")
  $volume=$disks | where {$_.SerialNumber -eq $volumeId}

  # Initialize disk and format volume
  $volume | Initialize-Disk -PartitionStyle MBR -PassThru | `
  New-Partition -UseMaximumSize -DriveLetter $driveLetter[$i+1] | `
  Format-Volume -FileSystem NTFS -Force

  # Add tags to ebs data volume
  $volumeName= $hostName + "_" + $driveLetter[$i+1]
  aws ec2 create-tags --resources $VOLUME_IDS[$i+1] --region $AWS_REGION --tags Key=Name,Value=$volumeName
}

# Add tags to ebs root volume
$volumeName= $hostName + "_" + $driveLetter[0]
aws ec2 create-tags --resources $ROOT_VOLUME_IDS --region $AWS_REGION --tags Key=Name,Value=$volumeName

# Add tags to network interface
aws ec2 create-tags --resources $NETWORK_INTERFACE_IDS --region $AWS_REGION --tags Key=Name,Value=$hostName"_ENI"

# Restart computer
Restart-Computer -Force
</powershell>