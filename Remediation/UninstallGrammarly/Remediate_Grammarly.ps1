#=============================================================================================================================
#
# Script Name:      Remediate_Grammarly.ps1
# Description:      Uninstall Grammarly
# Author:           Danny Chrismas - TheAutisticTechie
#
#=============================================================================================================================

$appdata = "$env:LOCALAPPDATA\Grammarly\DesktopIntegrations"
$appdataTest = test-path -path $appdata
$regKey = test-path -path "hkcu\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Grammarly Desktop Integrations"

try {
    if(($regKey) -or ($appdataTest)){
        write-host "Detected, attempting uninstall"
        & $appdata\Uninstall.exe /S
        exit 0 # detected
    } else {
        Write-host "Not Detected"
        exit 1 # doesn't exist
    }
}
catch {
    $errMsg = $_.Exception.Message
    Write-Error $errMsg
    exit 1
}
