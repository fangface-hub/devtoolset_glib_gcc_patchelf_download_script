$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$logFile = Join-Path $scriptDir ("{0}.log" -f [System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Name))
Start-Transcript -Path $logFile | Out-Null

try {
    # 共通関数を読み込む
    . "$PSScriptRoot\common-download.ps1"

    $saveDir = Join-Path $scriptDir 'gcc12.2_tarball'

    # 既存ディレクトリは保持し、無ければ作成
    if (-not (Test-Path $saveDir)) {
        New-Item -ItemType Directory -Path $saveDir | Out-Null
    }

    # ダウンロード処理
    $urls = @(
        "https://ftp.gnu.org/gnu/gcc/gcc-12.2.0/gcc-12.2.0.tar.xz",
        "https://ftp.gnu.org/gnu/gmp/gmp-6.2.1.tar.xz",
        "https://www.mpfr.org/mpfr-4.1.0/mpfr-4.1.0.tar.xz",
        "https://ftp.gnu.org/gnu/mpc/mpc-1.2.1.tar.gz"
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
