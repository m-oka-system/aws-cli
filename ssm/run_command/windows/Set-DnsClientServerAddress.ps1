# EC2 metadata
$AWS_AVAIL_ZONE = (curl http://169.254.169.254/latest/meta-data/placement/availability-zone).Content
$AWS_REGION = $AWS_AVAIL_ZONE.Substring(0,$AWS_AVAIL_ZONE.length-1)
#$AWS_REGION = "ap-southeast-1"

# 変数
$client = Get-NetAdapter | Get-DnsClient
$primaryDnsServer = ($client | Get-DnsClientServerAddress -AddressFamily IPv4).ServerAddresses[0]
$jpnDns = "10.0.0.2"
$sgpDns = "10.1.0.2"

# DNSキャッシュを削除
ipconfig /flushdns

try
{
  # DNSサーバを設定
  switch ($AWS_REGION) {
    "ap-northeast-1" {
      if ($primaryDnsServer -ne $jpnDns) {
        $client | Set-DnsClientServerAddress -ResetServerAddresses
      }
    }
    "ap-southeast-1" {
      if ($primaryDnsServer -ne $sgpDns) {
        $client | Set-DnsClientServerAddress -ServerAddresses $sgpDns
      }
    }
  }
}
catch
{
  Write-Host "DNSサーバの設定処理で例外が発生しました。処理を終了します。"
  exit 1
}

# 変更後設定確認
$client | Get-DnsClientServerAddress -AddressFamily IPv4 | FL

try
{
  # DNSサフィックスを設定
  $SuffixSearchList=@("${AWS_REGION}.ec2-utilities.amazonaws.com","${AWS_REGION}.compute.internal","m-oka-system.com")
  Set-DnsClientGlobalSetting -SuffixSearchList @($SuffixSearchList)
  (Get-DnsClientGlobalSetting).SuffixSearchList
}
catch
{
  Write-Host "DNSサフィックスの設定処理で例外が発生しました。処理を終了します。"
  exit 1
}
