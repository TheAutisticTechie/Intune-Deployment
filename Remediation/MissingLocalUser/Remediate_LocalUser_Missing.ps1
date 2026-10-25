#=============================================================================================================================
#
# Script Name:      Remediate_LocalUser_Missing.ps1
# Description:      Remediates the local user used for LAPS if it was missing
#                   Currently doesn't work with LAPS
# Author:           Danny Chrismas - TheAutisticTechie
#
#=============================================================================================================================

# Variables
$user = "helpdesk"

try {
    $exists = Get-LocalUser $user -ErrorAction SilentlyContinue
    if(!$exists) {
        # Random password nobody knows, so the account is never left with a blank password before LAPS manages it
        $bytes = New-Object byte[] 24
        [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
        $password = ConvertTo-SecureString ([Convert]::ToBase64String($bytes)) -AsPlainText -Force
        New-LocalUser -Name $user -Password $password -Description "LAPS"
        Get-ScheduledTask | Where-Object {$_.TaskName -eq 'PushLaunch'} | Start-ScheduledTask
        exit 0
    }
}
catch {
    $errMsg = $_.Exception.Message
    Write-Error $errMsg
    exit 1
}
