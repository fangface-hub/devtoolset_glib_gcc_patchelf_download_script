$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$logFile = Join-Path $scriptDir ("{0}.log" -f [System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Name))
Start-Transcript -Path $logFile | Out-Null

try {
	# 共通関数を読み込む
	. "$PSScriptRoot\common-download.ps1"

	# 保存先ディレクトリ
	$saveDir = Join-Path $PSScriptRoot 'patchelf0.18_tarball'
	if (Test-Path $saveDir) { Remove-Item $saveDir -Recurse -Force }
	New-Item -ItemType Directory -Path $saveDir | Out-Null

	# ダウンロード
	$url = "https://github.com/NixOS/patchelf/releases/download/0.18.0/patchelf-0.18.0.tar.gz"
	$out = Join-Path $saveDir "patchelf-0.18.0.tar.gz"

	Get-File -Url $url -Out $out

	Write-Host "Done. Files saved to $saveDir"
}
finally {
	try {
		Stop-Transcript | Out-Null
	}
	catch {
	}
}