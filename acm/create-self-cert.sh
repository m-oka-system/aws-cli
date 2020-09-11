#!/usr/bin/env bash

# 変数
domainName="example.com"
keyName="private-key"

# ディレクトリを作成
dir=./certdir/
mkdir -p ${dir}

# 秘密鍵を作成
openssl genrsa 2048 > ${dir}${keyName}.pem

# 証明書署名リクエスト(CSR)を作成
openssl req -new -key ${dir}${keyName}.pem -out ${dir}${keyName}.csr -subj "/C=JP/ST=Tokyo/O=example/CN=*.${domainName}"

# Subject Alternative Name指定用のファイルを作成
echo subjectAltName=DNS:*.${domainName} > ${dir}san.txt

# 自己証明書を作成(有効期限は1年)
openssl x509 -extfile ${dir}san.txt -req -days 365 -signkey ${dir}${keyName}.pem < ${dir}${keyName}.csr > ${dir}${domainName}.pem

# ブラウザへインポートするためのCRT証明書に変換
openssl x509 -in ${dir}${domainName}.pem -inform PEM -out ${dir}${domainName}.crt

# 不要ファイルを削除
rm ${dir}san.txt
rm ${dir}${keyName}.csr

# ACMへ証明書をインポート
aws acm import-certificate --certificate fileb://${dir}${domainName}.pem --private-key fileb://${dir}${keyName}.pem
