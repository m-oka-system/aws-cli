#!/bin/bash

# 変数
AWS_AVAIL_ZONE=$(curl http://169.254.169.254/latest/meta-data/placement/availability-zone)
AWS_REGION="`echo \"$AWS_AVAIL_ZONE\" | sed 's/[a-z]$//'`"
OS_RELEASE=$(grep REDHAT_BUGZILLA_PRODUCT_VERSION /etc/os-release)
OS_VERSION=${OS_RELEASE#*=}

case "$AWS_REGION" in
  "ap-northeast-1")OLD_AWS_REGION="ap-southeast-1" ;;
  "ap-southeast-1")OLD_AWS_REGION="ap-northeast-1" ;;
esac

# AWS CONFIGのデフォルトリージョンを修正
sed -i".org" -e "s/$OLD_AWS_REGION/$AWS_REGION/g" /root/.aws/config

case "$AWS_REGION" in
  "ap-northeast-1")
    case "$OS_VERSION" in
      # RHEL7の場合
      7*)
        # NetworkManager.confのmainセクションに"dns=none"があれば削除してNetworkManagerを有効化
        if [ -n "$(grep 'dns=none' /etc/NetworkManager/NetworkManager.conf)" ]; then
          sed -i".org" -e '/dns=none/d' /etc/NetworkManager/NetworkManager.conf
          sudo systemctl restart NetworkManager
        fi
      ;;
      # RHEL8の場合
      8*)
        # 90-dns-none.confがあればリネームしてNetworkManagerを有効化
        if [ -e /etc/NetworkManager/conf.d/90-dns-none.conf ]; then
          sudo mv /etc/NetworkManager/conf.d/90-dns-none.conf /etc/NetworkManager/conf.d/90-dns-none.conf.org
          sudo systemctl restart NetworkManager
        fi
      ;;
    esac
  ;;
  "ap-southeast-1")
    case "$OS_VERSION" in
      # RHEL7の場合
      7*)
        # NetworkManager.confのmainセクションに"dns=none"を追加してNetworkManagerを無効化
        if [ -z "$(grep 'dns=none' /etc/NetworkManager/NetworkManager.conf)" ]; then
          sed -i".org" -e '/\[main\]/a\dns=none' /etc/NetworkManager/NetworkManager.conf
        fi
      ;;
      # RHEL8の場合
      8*)
        # 90-dns-none.confをヒアドキュメントで新規作成してNetworkManagerを無効化
        if [ ! -e /etc/NetworkManager/conf.d/90-dns-none.conf ]; then
          cat << EOF > /etc/NetworkManager/conf.d/90-dns-none.conf
[main]
dns=none
EOF
        fi
      ;;
    esac

    # resolv.confにDNSサフィックスを追加
    if [ -z "$(grep 'm-oka-system.com' /etc/resolv.conf)" ]; then
      sed -i".org" -e '/^search/s/$/ m-oka-system.com'/ /etc/resolv.conf
    fi

    # resolv.confにDNSサーバを追加
    if [ -z "$(grep '10.1.0.2' /etc/resolv.conf)" ]; then
      sed -i".org" -e '/^search/a\nameserver 10.1.0.2' /etc/resolv.conf
    fi

    sudo systemctl restart NetworkManager
  ;;
esac
