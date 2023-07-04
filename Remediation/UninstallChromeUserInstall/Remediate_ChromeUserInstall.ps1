#=============================================================================================================================
#
# Script Name:    Remediate_ChromeUserInstall.ps1
# Description:    Uninstall Chrome from the user profile
#
#=============================================================================================================================

$userData = "$env:LOCALAPPDATA\Google\Chrome\User Data"
$appdata = "$env:LOCALAPPDATA\Google\Chrome\Application"
$appdataTest = test-path -path $appdata
$regKey = test-path -path "hkcu\Google\Chrome\Application"

try {
    if(($regKey) -or ($appdataTest)){
        write-host Detected
        $version = (Get-ChildItem -Directory $appdata | where-object Name -NotLike "SetupMetrics").name
        $installer = "$appdata\$version\Installer\setup.exe"
        & $installer --uninstall --force-uninstall
        remove-item -Path $userData -Force -Recurse
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
