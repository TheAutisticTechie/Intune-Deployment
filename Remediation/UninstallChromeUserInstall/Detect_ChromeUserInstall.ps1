#=============================================================================================================================
#
# Script Name:      Detect_ChromeUserInstall.ps1
# Description:      Detects if Chrome is installed at the user level
# Author:           Danny Chrismas - TheAutisticTechie
#
#=============================================================================================================================
$appdata = "$env:LOCALAPPDATA\Google\Chrome\Application"
$appdataTest = test-path -path $appdata
$regKey = test-path -path "hkcu\Google\Chrome\Application"

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
