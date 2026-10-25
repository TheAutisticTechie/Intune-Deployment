#=============================================================================================================================
#
# Script Name:      Remediate_Grammarly.ps1
# Description:      Uninstall Grammarly
# Author:           Danny Chrismas - TheAutisticTechie
#
#=============================================================================================================================

$appdata = "$env:LOCALAPPDATA\Grammarly\DesktopIntegrations"
$uninstallKey = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Grammarly Desktop Integrations"
$appdataTest = test-path -path $appdata
$regKey = test-path -path $uninstallKey

try {
    if(($regKey) -or ($appdataTest)){
        write-host "Detected, attempting uninstall"
        if (test-path -path "$appdata\Uninstall.exe") {
            & $appdata\Uninstall.exe /S
        } else {
            # Uninstaller is gone, so clear the leftover folder and uninstall entry so detection passes
            remove-item -Path $appdata, $uninstallKey -Force -Recurse -ErrorAction SilentlyContinue
        }
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
