#=============================================================================================================================
#
# Script Name:    Remediate_Zoom.ps1
# Description:    Uninstall Zoom
#
#=============================================================================================================================

$appdata = "$env:APPDATA\Zoom\bin\zoom.exe"
$appdataTest = test-path -path $appdata
$regKey = test-path -path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\ZoomUMX"

try {
    if(($regKey) -or ($appdataTest)){
        write-host "Detected, attempting uninstall"
        & $env:APPDATA\Zoom\uninstall\installer.exe /uninstall
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
