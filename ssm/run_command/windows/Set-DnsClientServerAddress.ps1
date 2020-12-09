# EC2 metadata
$AWS_AVAIL_ZONE = (curl http://169.254.169.254/latest/meta-data/placement/availability-zone).Content
$AWS_REGION = $AWS_AVAIL_ZONE.Substring(0,$AWS_AVAIL_ZONE.length-1)
# $AWS_REGION = "ap-northeast-1"

# 変数
$dnsServers = "10.0.0.2"

# NIC情報からDNS Clientオブジェクト取得
$client = Get-NetAdapter | Get-DnsClient

# 変更前設定確認
$client | Get-DnsClientServerAddress -AddressFamily IPv4

# 設定変更
switch ($AWS_REGION) {
  "ap-northeast-1" { $client | Set-DnsClientServerAddress -ResetServerAddresses }
  "ap-southeast-1" { $client | Set-DnsClientServerAddress -ServerAddresses $dnsServers }
}

# 変更後設定確認
$client | Get-DnsClientServerAddress -AddressFamily IPv4
