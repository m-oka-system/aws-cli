# EC2 metadata
$AWS_AVAIL_ZONE = (curl http://169.254.169.254/latest/meta-data/placement/availability-zone).Content
$AWS_REGION = $AWS_AVAIL_ZONE.Substring(0,$AWS_AVAIL_ZONE.length-1)
#$AWS_REGION = "ap-southeast-1"

# 旧リージョンを定義
switch ($AWS_REGION) {
  "ap-northeast-1" { $OLD_AWS_REGION = "ap-southeast-1" }
  "ap-southeast-1" { $OLD_AWS_REGION = "ap-northeast-1" }
}

# 現在のDNSサフィックスを取得
$BeforeSuffixSearchList = @(Get-DnsClientGlobalSetting).SuffixSearchList

# 変更後の値を格納する空の配列を作成
$AfterSuffixSearchList = @()

foreach ($s in $BeforeSuffixSearchList)
{
  if ($s -match $OLD_AWS_REGION) {
    $s = $s -replace $OLD_AWS_REGION, $AWS_REGION
    $AfterSuffixSearchList += $s
  }
  else {
    $AfterSuffixSearchList += $s
  }
}

Set-DnsClientGlobalSetting -SuffixSearchList $AfterSuffixSearchList
(Get-DnsClientGlobalSetting).SuffixSearchList
