# ============================
# common-download.ps1
# ============================

# ---- プロキシ設定（必要なら編集） ----
# ProxyServer は現在の接続設定から自動取得します
$Global:ProxyUser = $null
$Global:ProxyPass = $null
$Global:PromptProxyCredential = $true

function Resolve-ProxyServerFromCurrentConnection {
    # 1) 既存の環境変数（最優先）
    $proxyCandidates = @(
        $env:HTTPS_PROXY,
        $env:HTTP_PROXY,
        $env:https_proxy,
        $env:http_proxy
    )
    foreach ($candidate in $proxyCandidates) {
        if ($candidate) {
            return $candidate.Trim()
        }
    }

    # 2) WinHTTP 設定（netsh）
    try {
        $netshOutput = netsh winhttp show proxy 2>$null
        foreach ($line in $netshOutput) {
            if ($line -match '^\s*Proxy Server\(s\)\s*:\s*(.+)$') {
                $raw = $matches[1].Trim()
                if ($raw -and $raw -notmatch '^Direct access') {
                    # http=host:port;https=host:port の形式にも対応
                    $parts = $raw -split ';'
                    $selected = $null
                    foreach ($part in $parts) {
                        if ($part -match '^\s*https\s*=\s*(.+)$') {
                            $selected = $matches[1].Trim()
                            break
                        }
                    }
                    if (-not $selected) {
                        foreach ($part in $parts) {
                            if ($part -match '^\s*http\s*=\s*(.+)$') {
                                $selected = $matches[1].Trim()
                                break
                            }
                        }
                    }
                    if (-not $selected) {
                        $selected = $raw
                    }
                    if ($selected -notmatch '^[a-zA-Z][a-zA-Z0-9+.-]*://') {
                        $selected = "http://$selected"
                    }
                    return $selected
                }
            }
        }
    }
    catch {
    }

    # 3) WinINet (インターネット オプション) 設定
    try {
        $inet = Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -ErrorAction Stop
        if ($inet.ProxyEnable -eq 1 -and $inet.ProxyServer) {
            $raw = [string]$inet.ProxyServer
            $parts = $raw -split ';'
            $selected = $null
            foreach ($part in $parts) {
                if ($part -match '^\s*https\s*=\s*(.+)$') {
                    $selected = $matches[1].Trim()
                    break
                }
            }
            if (-not $selected) {
                foreach ($part in $parts) {
                    if ($part -match '^\s*http\s*=\s*(.+)$') {
                        $selected = $matches[1].Trim()
                        break
                    }
                }
            }
            if (-not $selected) {
                $selected = $raw.Trim()
            }
            if ($selected -and $selected -notmatch '^[a-zA-Z][a-zA-Z0-9+.-]*://') {
                $selected = "http://$selected"
            }
            return $selected
        }
    }
    catch {
    }

    return $null
}

function Show-ProxyCredentialDialog {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'プロキシ認証'
    $form.StartPosition = 'CenterScreen'
    $form.FormBorderStyle = 'FixedDialog'
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.ClientSize = New-Object System.Drawing.Size(420, 180)
    $form.TopMost = $true

    $labelUser = New-Object System.Windows.Forms.Label
    $labelUser.Text = 'ユーザー名'
    $labelUser.Location = New-Object System.Drawing.Point(20, 20)
    $labelUser.AutoSize = $true
    $form.Controls.Add($labelUser)

    $textUser = New-Object System.Windows.Forms.TextBox
    $textUser.Location = New-Object System.Drawing.Point(120, 18)
    $textUser.Size = New-Object System.Drawing.Size(280, 24)
    $form.Controls.Add($textUser)

    $labelPass = New-Object System.Windows.Forms.Label
    $labelPass.Text = 'パスワード'
    $labelPass.Location = New-Object System.Drawing.Point(20, 60)
    $labelPass.AutoSize = $true
    $form.Controls.Add($labelPass)

    $textPass = New-Object System.Windows.Forms.TextBox
    $textPass.Location = New-Object System.Drawing.Point(120, 58)
    $textPass.Size = New-Object System.Drawing.Size(280, 24)
    $textPass.UseSystemPasswordChar = $true
    $form.Controls.Add($textPass)

    $btnOk = New-Object System.Windows.Forms.Button
    $btnOk.Text = 'OK'
    $btnOk.Location = New-Object System.Drawing.Point(244, 110)
    $btnOk.Size = New-Object System.Drawing.Size(75, 28)
    $btnOk.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.Controls.Add($btnOk)

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = 'キャンセル'
    $btnCancel.Location = New-Object System.Drawing.Point(325, 110)
    $btnCancel.Size = New-Object System.Drawing.Size(75, 28)
    $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.Controls.Add($btnCancel)

    $form.AcceptButton = $btnOk
    $form.CancelButton = $btnCancel

    $dialogResult = $form.ShowDialog()
    if ($dialogResult -eq [System.Windows.Forms.DialogResult]::OK) {
        return @{
            User = $textUser.Text
            Pass = $textPass.Text
            Cancelled = $false
        }
    }

    return @{
        User = $null
        Pass = $null
        Cancelled = $true
    }
}

$Global:ProxyServer = Resolve-ProxyServerFromCurrentConnection

# ---- 認証付きプロキシ対応 ----
$Global:ProxyCredential = $null
if ($ProxyServer) {
    try {
        $serverUri = [System.Uri]$ProxyServer
        if ($serverUri.UserInfo) {
            $userInfoParts = $serverUri.UserInfo -split ':', 2
            $Global:ProxyUser = [System.Uri]::UnescapeDataString($userInfoParts[0])
            if ($userInfoParts.Count -gt 1) {
                $Global:ProxyPass = [System.Uri]::UnescapeDataString($userInfoParts[1])
            }
        }
    }
    catch {
    }
}

if ($ProxyServer -and -not $ProxyUser -and $PromptProxyCredential) {
    $inputCredential = Show-ProxyCredentialDialog
    if (-not $inputCredential.Cancelled) {
        $Global:ProxyUser = $inputCredential.User
        $Global:ProxyPass = $inputCredential.Pass
    } else {
        Write-Host "プロキシ認証情報の入力がキャンセルされました。認証なしで続行します。" -ForegroundColor Yellow
    }
}

if (-not $ProxyCredential -and $ProxyUser -and $ProxyPass) {
    $secure = ConvertTo-SecureString $ProxyPass -AsPlainText -Force
    $Global:ProxyCredential = New-Object System.Management.Automation.PSCredential($ProxyUser, $secure)
}

# ---- 環境変数用プロキシ文字列を組み立て ----
$Global:HttpProxyEnv = $null
$Global:HttpsProxyEnv = $null
if ($ProxyServer) {
    try {
        $builder = [System.UriBuilder]$ProxyServer
        if ($ProxyUser -and $ProxyPass) {
            # UriBuilder が必要なエスケープを行う
            $builder.UserName = $ProxyUser
            $builder.Password = $ProxyPass
        }

        $proxyEnvValue = $builder.Uri.AbsoluteUri.TrimEnd('/')
        $Global:HttpProxyEnv = $proxyEnvValue
        $Global:HttpsProxyEnv = $proxyEnvValue

        $env:HTTP_PROXY = $proxyEnvValue
        $env:HTTPS_PROXY = $proxyEnvValue
        $env:http_proxy = $proxyEnvValue
        $env:https_proxy = $proxyEnvValue
    }
    catch {
        Write-Host "ProxyServer の形式が不正です: $ProxyServer" -ForegroundColor Yellow
    }
}

# ---- ダウンロード関数（共通） ----
function Get-WebHtml {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url
    )

    return Invoke-WebRequestWithProxy -Url $Url
}

function Invoke-WebRequestWithProxy {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url,
        [string]$Method = 'Get',
        [hashtable]$Headers,
        [string]$OutFile
    )

    $invokeParams = @{
        Uri = $Url
        Method = $Method
        UseBasicParsing = $true
    }

    if ($Headers) {
        $invokeParams.Headers = $Headers
    }
    if ($OutFile) {
        $invokeParams.OutFile = $OutFile
    }
    if ($ProxyServer) {
        $invokeParams.Proxy = $ProxyServer
    }
    if ($ProxyCredential) {
        $invokeParams.ProxyCredential = $ProxyCredential
    }

    return Invoke-WebRequest @invokeParams
}

function Get-RemoteFileSize {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url
    )

    try {
        $response = Invoke-WebRequestWithProxy -Url $Url -Method Head
        $contentLength = $response.Headers['Content-Length']
        if ($contentLength) {
            return [long]$contentLength
        }
    }
    catch {
    }

    return $null
}

function Invoke-RangeDownloadWithProxy {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url,
        [Parameter(Mandatory = $true)]
        [string]$OutFile,
        [Parameter(Mandatory = $true)]
        [long]$StartByte
    )

    $request = [System.Net.HttpWebRequest]::Create($Url)
    $request.Method = 'GET'
    $request.AddRange($StartByte)

    if ($ProxyServer) {
        $proxy = New-Object System.Net.WebProxy($ProxyServer, $true)
        if ($ProxyUser -and $ProxyPass) {
            $proxy.Credentials = New-Object System.Net.NetworkCredential($ProxyUser, $ProxyPass)
        }
        $request.Proxy = $proxy
    }

    $response = $null
    $responseStream = $null
    $destination = $null

    try {
        $response = [System.Net.HttpWebResponse]$request.GetResponse()
        $statusCode = [int]$response.StatusCode

        if ($statusCode -eq 206) {
            $destination = [System.IO.File]::Open($OutFile, [System.IO.FileMode]::Append, [System.IO.FileAccess]::Write, [System.IO.FileShare]::Read)
        }
        else {
            # サーバがRange未対応ならフルデータで作り直す
            $destination = [System.IO.File]::Open($OutFile, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write, [System.IO.FileShare]::Read)
        }

        $responseStream = $response.GetResponseStream()
        $responseStream.CopyTo($destination)

        return $statusCode
    }
    finally {
        if ($destination) {
            $destination.Dispose()
        }
        if ($responseStream) {
            $responseStream.Dispose()
        }
        if ($response) {
            $response.Dispose()
        }
    }
}

function Get-File {
    param(
        [string]$Url,
        [string]$Out
    )

    Write-Host "Downloading $Url ..."
    try {
        $remoteSize = Get-RemoteFileSize -Url $Url
        $localSize = 0
        if (Test-Path $Out) {
            $localSize = (Get-Item $Out).Length
        }

        if ($localSize -gt 0 -and $remoteSize -and $localSize -ge $remoteSize) {
            Write-Host "Already complete: $Out"
            return
        }

        if ($localSize -gt 0) {
            Write-Host "Resuming from byte $localSize ..."
            $statusCode = Invoke-RangeDownloadWithProxy -Url $Url -OutFile $Out -StartByte $localSize
            if ($statusCode -ne 206) {
                Write-Host "Range unsupported. Re-downloaded full file." -ForegroundColor Yellow
            }
        } else {
            Invoke-WebRequestWithProxy -Url $Url -OutFile $Out | Out-Null
        }

        if ($remoteSize) {
            $finalSize = (Get-Item $Out).Length
            if ($finalSize -ne $remoteSize) {
                Write-Host "Warning: expected size=$remoteSize, actual size=$finalSize" -ForegroundColor Yellow
            }
        }

        Write-Host "Saved to $Out"
    }
    catch {
        Write-Host "Failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}