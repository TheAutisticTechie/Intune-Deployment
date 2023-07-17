#=============================================================================================================================
#
# Script Name:    Detect_Zoom.ps1
# Description:    Detects if Zoom is installed
#
#=============================================================================================================================

$appdata = "$env:APPDATA\Zoom\bin\zoom.exe"
$appdataTest = test-path -path $appdata
$regKey = test-path -path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\ZoomUMX"

try {
    if(($regKey) -or ($appdataTest)){
        write-host "Detected"
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
