try
{
  Import-Module "C:\ProgramData\Amazon\EC2-Windows\Launch\Module\Ec2Launch.psd1"
  Add-Routes
  Set-Activationsettings
  cscript "${env:SYSTEMROOT}\system32\slmgr.vbs" /ato
}
catch
{
  Write-Host "ライセンス認証の処理で例外が発生しました。処理を終了します。"
  exit 1
}

try
{
  # Get license status
  $Status = cscript $env:WinDir\System32\slmgr.vbs /dli

  # Get language environment
  $NowLanguage = [System.Globalization.CultureInfo]::CurrentCulture.Name

  # when ja-JP
  if( $NowLanguage -eq "ja-JP" ){
      [array]$LicenseStatus = $Status | Select-String "ライセンスの状態"
      if( $LicenseStatus.Length -eq 1 ){
          if( $LicenseStatus[0] -match "ライセンスされています" ){
              Write-Host "OK:Licensed"
          }
          else{
              Write-Host "NG:Unlicensed"
              exit 1
          }
      }
      else{
          Write-Host "NG:Unknown status"
          exit 1
      }
  }
  # when other than ja-JP
  else{
      [array]$LicenseStatus = $Status | Select-String "License Status"
      if( $LicenseStatus.Length -eq 1 ){
          if( $LicenseStatus[0] -match "Licensed" ){
              Write-Host "OK:Licensed"
          }
          else{
              Write-Host "NG:Unlicensed"
              exit 1
          }
      }
      else{
          Write-Host "NG:Unknown status"
          exit 1
      }
  }
}
catch
{
  Write-Host "ライセンス認証の結果確認で例外が発生しました。処理を終了します。"
}
