#=============================================================================================================================
#
# Script Name:      Remediate_LocalUser_Missing.ps1
# Description:      Remediates the local user used for LAPS if it was missing
#                   Currently doesn't work with LAPS
#
#=============================================================================================================================

# Variables
$user = "helpdesk"

try {
    $exists = Get-LocalUser $user -ErrorAction SilentlyContinue
    if(!$exists) {
        New-LocalUser -Name $user -NoPassword -Description "LAPS"
        Get-ScheduledTask | Where-Object {$_.TaskName -eq 'PushLaunch'} | Start-ScheduledTask
        exit 0
    }
}
catch {
    $errMsg = $_.Exception.Message
    Write-Error $errMsg
    exit 1
}