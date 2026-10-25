#=============================================================================================================================
#
# Script Name:      Remediate_LocalUser_Missing.ps1
# Description:      Remediates the local user used for LAPS if it was missing
#                   Currently doesn't work with LAPS
# Author:           Danny Chrismas - TheAutisticTechie
#
#=============================================================================================================================

# Intune runs remediation scripts in 32-bit PowerShell unless "Run script in 64-bit PowerShell" is enabled, and the
# LocalAccounts cmdlets (Get-LocalUser, New-LocalUser) don't exist there. Relaunch in the native host
if ($env:PROCESSOR_ARCHITEW6432 -and (Test-Path "$env:SystemRoot\SysNative\WindowsPowerShell\v1.0\powershell.exe")) {
    & "$env:SystemRoot\SysNative\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File $PSCommandPath
    exit $LASTEXITCODE
}

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
