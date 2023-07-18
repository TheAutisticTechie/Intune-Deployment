#=============================================================================================================================
#
# Script Name:      Remediate_Zoom.ps1
# Description:      Uninstall Zoom
# Author:           Danny Chrismas - TheAutisticTechie
#
#=============================================================================================================================

$appdata = "$env:APPDATA\Zoom\bin\zoom.exe"
$appdataTest = test-path -path $appdata
$regKey = test-path -path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\ZoomUMX"

try {
    if(($regKey) -or ($appdataTest)){
        $process = get-process zoom -ErrorAction SilentlyContinue
        write-host "Detected, attempting uninstall"
        if (!$process){
            $job = Start-Job { & $env:APPDATA\Zoom\uninstall\installer.exe /uninstall /silent }
            Wait-Job $job
            Receive-Job $job
            Start-Sleep -Seconds 30#uninstaller ends writing to the log at different speeds
            remove-item $env:APPDATA\Zoom\ -Force -Recurse
            exit 0 # detected
        }
        else {
            write-host "Error: meeting in progress. Ending Uninstall attempt"
            exit 1
        }
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
