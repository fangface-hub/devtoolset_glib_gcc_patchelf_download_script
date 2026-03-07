$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$logFile = Join-Path $scriptDir ("{0}.log" -f [System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Name))
Start-Transcript -Path $logFile | Out-Null

try {
    # 共通関数を読み込む
    . "$PSScriptRoot\common-download.ps1"

    $saveDir = Join-Path $scriptDir 'glib2.29_tarball'

    # 既存ディレクトリは保持し、無ければ作成
    if (-not (Test-Path $saveDir)) {
        New-Item -ItemType Directory -Path $saveDir | Out-Null
    }

    # ダウンロード処理
    $url = "https://ftp.gnu.org/gnu/glibc/glibc-2.29.tar.gz"
    $out = Join-Path $saveDir "glibc-2.29.tar.gz"
    Get-File -Url $url -Out $out

    Write-Host "Done. RPMs saved to $saveDir"
}
finally {
    try {
        Stop-Transcript | Out-Null
    }
    catch {
    }
}