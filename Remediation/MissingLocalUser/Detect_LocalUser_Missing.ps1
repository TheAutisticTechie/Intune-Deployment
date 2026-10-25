#=============================================================================================================================
#
# Script Name:      Detect_LocalUser_Missing.ps1
# Description:      Detects if the local user used for LAPS is missing or present
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
$exists = Get-LocalUser $user -ErrorAction SilentlyContinue

try {
    if(!$exists) {
        Write-Host "Missing Local User"
        exit 1
    }
    else {
        Write-Host "Local User Present"
        exit 0
    }
}
catch {
    $errMsg = $_.Exception.Message
    Write-Error $errMsg
    exit 1
}
