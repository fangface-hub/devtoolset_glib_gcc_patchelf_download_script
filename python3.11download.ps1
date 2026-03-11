$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$logFile = Join-Path $scriptDir ("{0}.log" -f [System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Name))
Start-Transcript -Path $logFile | Out-Null

try {
    # 共通関数を読み込む
    . "$PSScriptRoot\common-download.ps1"

    $saveDir = Join-Path $scriptDir 'python3.11_tarball'

    # 既存ディレクトリは保持し、無ければ作成
    if (-not (Test-Path $saveDir)) {
        New-Item -ItemType Directory -Path $saveDir | Out-Null
    }

    # ダウンロード処理
    $urls = @(
        "https://www.python.org/ftp/python/3.11.9/Python-3.11.9.tgz",
        "https://github.com/openssl/openssl/releases/download/openssl-3.0.18/openssl-3.0.18.tar.gz"
    )
    foreach ($url in $urls) {
        $filename = Split-Path $url -Leaf
        $out = Join-Path $saveDir $filename
        Get-File -Url $url -Out $out
    }

    Write-Host "Done. files saved to $saveDir"
}
finally {
    try {
        Stop-Transcript | Out-Null
    }
    catch {
    }
}
