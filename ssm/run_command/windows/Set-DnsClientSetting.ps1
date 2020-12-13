# EC2 metadata
$AWS_AVAIL_ZONE = (curl http://169.254.169.254/latest/meta-data/placement/availability-zone).Content
$AWS_REGION = $AWS_AVAIL_ZONE.Substring(0,$AWS_AVAIL_ZONE.length-1)
#$AWS_REGION = "ap-southeast-1"

# 変数
$JpnDnsServer = "10.0.0.2"
$SgpDnsServer = "10.1.0.2"

# DNSキャッシュを削除
ipconfig /flushdns

try
{
  # 現在のDNSサーバを取得
  $client = Get-NetAdapter | Get-DnsClient
  $BeforePrimaryDnsServer = ($client | Get-DnsClientServerAddress -AddressFamily IPv4).ServerAddresses[0]

  # DNSサーバを設定
  switch ($AWS_REGION) {
    "ap-northeast-1" {
      if ($BeforePrimaryDnsServer -ne $JpnDnsServer) {
        $client | Set-DnsClientServerAddress -ResetServerAddresses
      }
    }
    "ap-southeast-1" {
      if ($BeforePrimaryDnsServer -ne $SgpDnsServer) {
        $client | Set-DnsClientServerAddress -ServerAddresses $SgpDnsServer
      }
    }
  }
}
catch
{
  Write-Host "DNSサーバの設定処理で例外が発生しました。処理を終了します。"
  exit 1
}


try
{
  # 変更後のDNSサーバを取得
  $AfterPrimaryDnsServer = ($client | Get-DnsClientServerAddress -AddressFamily IPv4).ServerAddresses[0]

  # DNSサーバが正しいかチェック
  switch ($AWS_REGION) {
    "ap-northeast-1" {
      if ($AfterPrimaryDnsServer -eq $JpnDnsServer) {
        Write-Host "OK:Primary dns server is ${AfterPrimaryDnsServer}"
      }
      else {
        Write-Host "NG:Primary dns server is ${AfterPrimaryDnsServer}"
        exit 1
      }
    }
    "ap-southeast-1" {
      if ($AfterPrimaryDnsServer -eq $SgpDnsServer) {
        Write-Host "OK:Primary dns server is ${AfterPrimaryDnsServer}"
      }
      else {
        Write-Host "NG:Primary dns server is ${AfterPrimaryDnsServer}"
        exit 1
      }
    }
  }
}
catch
{
  Write-Host "DNSサーバの設定確認で例外が発生しました。処理を終了します。"
  exit 1
}

try
{
  # DNSサフィックスを設定
  $SuffixSearchList=@("${AWS_REGION}.ec2-utilities.amazonaws.com","${AWS_REGION}.compute.internal","m-oka-system.com")
  Set-DnsClientGlobalSetting -SuffixSearchList @($SuffixSearchList)
}
catch
{
  Write-Host "DNSサフィックスの設定処理で例外が発生しました。処理を終了します。"
  exit 1
}


try
{
  # 変更後のDNSサフィックスを取得
  $AfterSuffixSearchList = @(Get-DnsClientGlobalSetting).SuffixSearchList
  $FirstSuffix = $AfterSuffixSearchList[0]
  $SecondSuffix = $AfterSuffixSearchList[1]

  # DNSサフィックスが正しいかチェック
  if( $AfterSuffixSearchList[0] -eq "${AWS_REGION}.ec2-utilities.amazonaws.com" ){
    Write-Host "OK:First dns suffix is $FirstSuffix"
  }
  else{
    Write-Host "NG:First dns suffix is $FirstSuffix"
    exit 1
  }

  if( $AfterSuffixSearchList[1] -eq "m-oka-system.com" ){
    Write-Host "OK:Second dns suffix is $SecondSuffix"
  }
  else{
    Write-Host "OK:Second dns suffix is $SecondSuffix"
    exit 1
  }
}
catch
{
  Write-Host "DNSサフィックスの設定確認で例外が発生しました。処理を終了します。"
  exit 1
}
