$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$logFile = Join-Path $scriptDir ("{0}.log" -f [System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Name))
Start-Transcript -Path $logFile | Out-Null

try {
    # 共通関数を読み込む
    . "$PSScriptRoot\common-download.ps1"

    # 保存ディレクトリのパスをスクリプトと同じフォルダに設定
    $saveDir = Join-Path $scriptDir 'devtoolset11_rpms'

    # 既存ディレクトリは保持し、無ければ作成
    if (-not (Test-Path $saveDir)) {
        New-Item -ItemType Directory -Path $saveDir | Out-Null
    }

# 必要なdevtoolset-11パッケージのプレフィックス一覧
$devtoolset_prefixes = @(
    "devtoolset\-11\-elfutils\-libelf",
    "devtoolset\-11\-dyninst",
    "devtoolset\-11\-strace",
    "devtoolset\-11\-make",
    "devtoolset\-11\-ltrace",
    "devtoolset\-11\-gcc\-c\+\+",
    "devtoolset\-11",
    "devtoolset\-11\-runtime",
    "devtoolset\-11\-elfutils\-libs",
    "devtoolset\-11\-elfutils",
    "devtoolset\-11\-binutils",
    "devtoolset\-11\-systemtap\-client",
    "devtoolset\-11\-dwz",
    "devtoolset\-11\-libstdc\+\+\-devel",
    "devtoolset\-11\-annobin\-docs",
    "devtoolset\-11\-oprofile",
    "devtoolset\-11\-memstomp",
    "devtoolset\-11\-gcc",
    "devtoolset\-11\-libquadmath\-devel",
    "devtoolset\-11\-toolchain",
    "devtoolset\-11\-systemtap\-devel",
    "devtoolset\-11\-perftools",
    "devtoolset\-11\-elfutils\-debuginfod\-client",
    "devtoolset\-11\-systemtap\-runtime",
    "devtoolset\-11\-gdb",
    "devtoolset\-11\-valgrind",
    "devtoolset\-11\-gcc-gfortran",
    "devtoolset\-11\-systemtap"
)

# RPM一覧ページからrpm取得
function Get-LatestRpms {
    param (
        [array]$prefixes,
        [string]$durl
    )
    Write-Host "Fetching RPM list from $durl ..."
    $html = Get-WebHtml -Url $durl
    $rpmNames = ($html.Links | Where-Object { $_.href -match "\.rpm$" } | ForEach-Object { $_.href })
    $latestRpms = @()
    foreach ($prefix in $prefixes) {
        $pattern = "^$prefix" + "\-\d.*\.(noarch|x86_64)\.rpm"
        $candidates = $rpmNames | Where-Object { $_ -match $pattern }
        if ($candidates.Count -eq 0) {
            Write-Host ("No candidates found for prefix: {0}" -f $prefix) -ForegroundColor Yellow
            continue
        }
        $latest = $candidates | Sort-Object { $_ -replace '[^0-9.]', '' } -Descending | Select-Object -First 1
        Write-Host ("Latest RPM for prefix '{0}': {1}" -f $prefix, $latest) -ForegroundColor Green
        $latestRpms += @{ name = $latest; url = "$durl$latest" }
    }
    return $latestRpms
}

# CentOS 7.9 vault の URL
$sclo_base = "https://vault.centos.org/7.9.2009/sclo/x86_64/rh"
$devtoolset_durl = "$sclo_base/Packages/d/"
$latestRpms = Get-LatestRpms -prefixes $devtoolset_prefixes -durl $devtoolset_durl


# scl-utils, scl-utils-buildはCentOS 7 baseリポジトリ(os/x86_64/Packages)から取得
$base_os = "http://vault.centos.org/centos/7/os/x86_64/Packages/"
$base_prefixes = @(
    "scl\-utils",
    "scl\-utils\-build",
    "avahi\-libs",
    "binutils",
    "boost\-system",
    "bzip2\-libs",
    "chkconfig",
    "coreutils",
    "elfutils",
    "elfutils\-devel",
    "elfutils\-libs",
    "expat",
    "glibc",
    "gmp",
    "grep",
    "info",
    "json\-c",
    "kernel\-debug-devel",
    "kernel\-devel",
    "libcurl",
    "libgcc",
    "libgfortran5",
    "libgomp",
    "libselinux",
    "libstdc\+\+",
    "make",
    "mokutil",
    "mpfr",
    "ncurses\-libs",
    "nspr",
    "nss",
    "openssh\-clients",
    "perl",
    "policycoreutils",
    "popt",
    "python\-libs",
    "readline",
    "scl\-utils",
    "sed",
    "shadow\-utils",
    "source\-highlight",
    "sqlite",
    "unzip",
    "util\-linux",
    "which",
    "xz\-libs",
    "zlib"
)
$latestRpms += Get-LatestRpms -prefixes $base_prefixes -durl $base_os

    # ダウンロード処理
    foreach ($item in $latestRpms) {
        $rpm = $item.name
        $url = $item.url
        $out = Join-Path $saveDir $rpm
        Get-File -Url $url -Out $out
    }

    Write-Host "Done. RPMs saved to $saveDir"
}
finally {
    try {
        Stop-Transcript | Out-Null
    }
    catch {
    }
}