#!/bin/bash

# Install aws cli v2
sudo yum install -y unzip
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# EC2 metadata
AWS_AVAIL_ZONE=$(curl http://169.254.169.254/latest/meta-data/placement/availability-zone)
AWS_REGION="`echo \"$AWS_AVAIL_ZONE\" | sed 's/[a-z]$//'`"
AWS_INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)
ROOT_VOLUME_IDS=$(aws ec2 describe-instances --region $AWS_REGION --instance-id $AWS_INSTANCE_ID --output text --query Reservations[0].Instances[0].BlockDeviceMappings[0].Ebs.VolumeId)
DATA_VOLUME_IDS=$(aws ec2 describe-instances --region $AWS_REGION --instance-id $AWS_INSTANCE_ID --output text --query Reservations[0].Instances[0].BlockDeviceMappings[].Ebs.VolumeId)
NETWORK_INTERFACE_IDS=$(aws ec2 describe-instances --region $AWS_REGION --instance-id $AWS_INSTANCE_ID --output text --query Reservations[0].Instances[0].NetworkInterfaces[].NetworkInterfaceId)

# Variables
HOST_NAME=$(aws ec2 describe-instances --region $AWS_REGION --instance-id $AWS_INSTANCE_ID --output text --query 'Reservations[].Instances[].Tags[?Key==`Name`].Value')

# Timezone
timedatectl set-timezone "Asia/Tokyo"

# Locale
localectl set-locale LANG=ja_JP.utf8
localectl set-keymap jp106
source /etc/locale.conf

# Hostname
hostnamectl set-hostname --static $HOST_NAME
echo "preserve_hostname: true" >> /etc/cloud/cloud.cfg

# Disable SELinux
sed -i".org" -e 's/^SELINUX=enforcing$/SELINUX=disabled/' /etc/selinux/config

# Add user
USER_NAME="aws_admin"
useradd -m $USER_NAME
echo "${USER_NAME}:P@ssw0rd" | chpasswd

# Allow password authentication
sed -i".org" -e 's/^PasswordAuthentication no$/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Add sudo permission(Edit /etc/sudoers)
echo "${USER_NAME} ALL=(ALL) NOPASSWD: ALL" | EDITOR='tee -a' visudo >/dev/null

# Add tags to ebs volume
aws ec2 create-tags --resources $DATA_VOLUME_IDS --region $AWS_REGION --tags Key=Name,Value=${HOST_NAME}_DATA
aws ec2 create-tags --resources $ROOT_VOLUME_IDS --region $AWS_REGION --tags Key=Name,Value=${HOST_NAME}_ROOT

# Add tags to network interface
aws ec2 create-tags --resources $NETWORK_INTERFACE_IDS --region $AWS_REGION --tags Key=Name,Value=${HOST_NAME}_ENI

# Install SSM agent
sudo yum install -y https://s3.${AWS_REGION}.amazonaws.com/amazon-ssm-${AWS_REGION}/latest/linux_amd64/amazon-ssm-agent.rpm
sudo systemctl enable amazon-ssm-agent
sudo systemctl start amazon-ssm-agent

# Install amazon-efs-utils
sudo yum install -y git
sudo yum install -y rpm-build
git clone https://github.com/aws/efs-utils
cd efs-utils
make rpm
sudo yum -y install build/amazon-efs-utils*rpm

# Install web server(nginx)
sudo rpm -ivh http://nginx.org/packages/rhel/7/noarch/RPMS/nginx-release-rhel-7-0.el7.ngx.noarch.rpm
sudo yum install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx
echo "<h1>$(hostname)</h1>" > index.html
sudo mv ./index.html  /usr/share/nginx/html/

# Restart computer
reboot
