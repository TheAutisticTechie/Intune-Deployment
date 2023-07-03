#=============================================================================================================================
#
# Script Name:    Detect_Grammarly.ps1
# Description:    Detects if Grammarly is installed
#
#=============================================================================================================================

$appdata = "$env:LOCALAPPDATA\Grammarly\DesktopIntegrations"
$regKey = "hkcu\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Grammarly Desktop Integrations"

try {
    if($regKey -or $appdata) {
        exit 1 # detected
    } else {
        exit 0 # doesn't exist
    }
}
catch {
    $errMsg = $_.Exception.Message
    Write-Error $errMsg
    exit 1
}
