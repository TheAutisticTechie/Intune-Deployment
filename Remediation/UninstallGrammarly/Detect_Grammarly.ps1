#=============================================================================================================================
#
# Script Name:    Detect_Grammarly.ps1
# Description:    Detects if Grammarly is installed
#
#=============================================================================================================================

$appdata = test-path -path "$env:LOCALAPPDATA\Grammarly\DesktopIntegrations"
$regKey = test-path -path "hkcu\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Grammarly Desktop Integrations"

try {
    if(($regKey -eq "True") -or ($appdata -eq "True")){
        write-host Detected
        exit 1 # detected
    } else {
        Write-host "Not Detected"
        exit 0 # doesn't exist
    }
}
catch {
    $errMsg = $_.Exception.Message
    Write-Error $errMsg
    exit 1
}
