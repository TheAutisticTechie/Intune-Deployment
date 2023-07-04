#=============================================================================================================================
#
# Script Name:    Remediate_Grammarly.ps1
# Description:    Uninstall Grammarly
#
#=============================================================================================================================

$appdata = test-path -path "$env:LOCALAPPDATA\Grammarly\DesktopIntegrations"
$regKey = test-path -path "hkcu\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Grammarly Desktop Integrations"

try {
    try {
        ."$appdata\Uninstall.exe /S"
        exit 0
    }
    catch {
        if(($regKey -eq "True") -or ($appdata -eq "True")){
            exit 0 # detected
        } else {
            exit 1 # doesn't exist
        }
    }
}
catch {
    $errMsg = $_.Exception.Message
    Write-Error $errMsg
    exit 1
}
