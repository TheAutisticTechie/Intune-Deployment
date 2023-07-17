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
        exit 1
        Write-Host "Missing Local User"
    }
    else {
        exit 0
        Write-Host "Local User Present"
    }
}
catch {
    $errMsg = $_.Exception.Message
    Write-Error $errMsg
    exit 1
}
