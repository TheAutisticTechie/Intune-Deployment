#=============================================================================================================================
#
# Script Name:    Remediate_Grammarly.ps1
# Description:    Uninstall Grammarly
#
#=============================================================================================================================

$appdata = "$env:LOCALAPPDATA\Grammarly\DesktopIntegrations"
$regKey = "hkcu\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Grammarly Desktop Integrations"

try {
    try {
        ."$appdata\Uninstall.exe /S"
        exit 0
    }
    catch {
        if($regKey -or $appdata) {
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
