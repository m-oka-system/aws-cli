#!/bin/bash

# 変数
AWS_AVAIL_ZONE=$(curl http://169.254.169.254/latest/meta-data/placement/availability-zone)
AWS_REGION="`echo \"$AWS_AVAIL_ZONE\" | sed 's/[a-z]$//'`"
OS_RELEASE=$(cat /etc/os-release)

case "$AWS_REGION" in
  "ap-northeast-1")
    # AWS CONFIGのデフォルトリージョンを修正
    OLD_AWS_REGION="ap-southeast-1"
    sed -i".org" -e "s/$OLD_AWS_REGION/$AWS_REGION/g" /root/.aws/config
  ;;
  "ap-southeast-1")
    # AWS CONFIGのデフォルトリージョンを修正
    OLD_AWS_REGION="ap-northeast-1"
    sed -i".org" -e "s/$OLD_AWS_REGION/$AWS_REGION/g" /root/.aws/config

    # NetworkManagerを無効化
    # RHEL7.7の場合はNetworkManager.confをメンテ
    if [ -n "$(echo "$OS_RELEASE" | grep -o "REDHAT_BUGZILLA_PRODUCT_VERSION=7.7")" ]; then
      sed -i".org" -e '/\[main\]/a\dns=none' /etc/NetworkManager/NetworkManager.conf
      sudo systemctl restart NetworkManager

    # RHEL8.3の場合は90-dns-none.confを新規作成してヒアドキュメントで追記
    elif [ -n "$(echo "$OS_RELEASE" | grep -o "REDHAT_BUGZILLA_PRODUCT_VERSION=8.3")" ]; then
      cat << EOF > /etc/NetworkManager/conf.d/90-dns-none.conf
[main]
dns=none
EOF
      sudo systemctl restart NetworkManager
    fi
  ;;
esac
