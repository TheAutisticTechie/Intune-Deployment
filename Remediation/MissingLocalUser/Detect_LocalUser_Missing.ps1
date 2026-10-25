#=============================================================================================================================
#
# Script Name:      Detect_LocalUser_Missing.ps1
# Description:      Detects if the local user used for LAPS is missing or present
# Author:           Danny Chrismas - TheAutisticTechie
#
#=============================================================================================================================

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
