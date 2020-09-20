<powershell>

# EC2 metadata
$AWS_AVAIL_ZONE = (curl http://169.254.169.254/latest/meta-data/placement/availability-zone).Content
$AWS_REGION = $AWS_AVAIL_ZONE.Substring(0,$AWS_AVAIL_ZONE.length-1)
$AWS_INSTANCE_ID = (curl http://169.254.169.254/latest/meta-data/instance-id).Content
$ROOT_VOLUME_IDS = aws ec2 describe-instances --region $AWS_REGION --instance-id $AWS_INSTANCE_ID --output text --query Reservations[0].Instances[0].BlockDeviceMappings[0].Ebs.VolumeId
$VOLUME_IDS = (aws ec2 describe-instances --region $AWS_REGION --instance-id $AWS_INSTANCE_ID --output text --query "sort_by(Reservations[0].Instances[0].BlockDeviceMappings[],&DeviceName)[].Ebs.VolumeId") -split "	"
$NETWORK_INTERFACE_IDS = (aws ec2 describe-instances --region $AWS_REGION --instance-id $AWS_INSTANCE_ID --output text --query Reservations[0].Instances[0].NetworkInterfaces[].NetworkInterfaceId)

# Variables
$DRIVE_LETTER=[char[]](67..90) #C..Z
$HOST_NAME=(aws ec2 describe-instances --region $AWS_REGION --instance-id $AWS_INSTANCE_ID --output text --query 'Reservations[].Instances[].Tags[?Key==`Name`].Value')

# Timezone
Set-TimeZone -id "Tokyo Standard Time"

# Hostname
Rename-Computer -NewName $HOST_NAME -Force

# Disable firewall
Get-NetFirewallProfile | Set-NetFirewallProfile -Enabled false

# Add local user
New-LocalUser -Name "user1" -Description "user1" -Password $(ConvertTo-SecureString -String YourPassword -AsPlainText -Force)
Add-LocalGroupMember -Group Administrators -Member "user1"

# Mount data disk
$DISKS = Get-Disk | sort Number | where { ($_.Number -ne 0) }
for ($i = 0; $i -lt @($DISKS).Length; $i++)
{
  $VOLUME_ID = $VOLUME_IDS[$i+1].Replace("-","")
  $VOLUME = $DISKS | where {$_.SerialNumber -like "${VOLUME_ID}*"}

  # Initialize disk and format volume
  $VOLUME | Initialize-Disk -PartitionStyle MBR -PassThru | `
  New-Partition -UseMaximumSize -DriveLetter $DRIVE_LETTER[$i+1] | `
  Format-Volume -FileSystem NTFS -Force

  # Add tags to ebs data volume
  $VOLUME_NAME = $HOST_NAME + "_" + $DRIVE_LETTER[$i+1]
  aws ec2 create-tags --resources $VOLUME_IDS[$i+1] --region $AWS_REGION --tags Key=Name,Value=$VOLUME_NAME
}

# Add tags to ebs root volume
$VOLUME_NAME = $HOST_NAME + "_" + $DRIVE_LETTER[0]
aws ec2 create-tags --resources $ROOT_VOLUME_IDS --region $AWS_REGION --tags Key=Name,Value=$VOLUME_NAME

# Add tags to network interface
aws ec2 create-tags --resources $NETWORK_INTERFACE_IDS --region $AWS_REGION --tags Key=Name,Value=$HOST_NAME"_ENI"

# Install web server(IIS)
Install-WindowsFeature web-server

# Create index.html to document root
New-Item -ItemType file -Path C:\inetpub\wwwroot\index.html -Value "<h1>$($HOST_NAME)</h1>"

# Restart computer
Restart-Computer -Force
</powershell>
