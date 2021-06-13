#!/bin/bash
set -euo pipefail

# 変数
USER_NAME="$1"

# メイン処理
# 仮想MFAデバイスを作成してQRコードを取得
aws iam create-virtual-mfa-device --virtual-mfa-device-name $USER_NAME --outfile ./qrcode.png --bootstrap-method QRCodePNG

# 仮想MFAデバイスの有効化
SERIAL_NUMBER=$(aws iam list-virtual-mfa-devices --query "VirtualMFADevices[?contains(SerialNumber,\`${USER_NAME}\`)].SerialNumber" --output text)
aws iam enable-mfa-device --user-name $USER_NAME --serial-number $SERIAL_NUMBER --authentication-code1 111111 --authentication-code2 222222
