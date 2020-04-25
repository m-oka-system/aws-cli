#!/bin/bash
hostnamectl set-hostname --static WEB01
echo "preserve_hostname: true" >> /etc/cloud/cloud.cfg
reboot
