# 変数
$ImportFile = "hosts-windows"
$ImportFIlePath = Join-Path $PSScriptRoot $ImportFile

# サーバ一覧のファイルを1行ずつ読み込んで配列へ格納
$servers = Get-Content $ImportFIlePath

# メイン処理
Write-Host "---ping start---"

foreach ($server in $servers)
{
  $result = Test-Connection $server -Count 1 -Quiet
  if ( $result )
  {
    Write-Host "${server}:success"
  }
  else
  {
    Write-Host "${server}:failed"
    exit 1
  }
}

Write-Host "---ping end---"
