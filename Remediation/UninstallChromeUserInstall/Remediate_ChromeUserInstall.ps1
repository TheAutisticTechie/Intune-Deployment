#=============================================================================================================================
#
# Script Name:      Remediate_ChromeUserInstall.ps1
# Description:      Uninstall Chrome from the user profile
# Author:           Danny Chrismas - TheAutisticTechie
#
#=============================================================================================================================

$userData = "$env:LOCALAPPDATA\Google\Chrome\User Data"
$appdata = "$env:LOCALAPPDATA\Google\Chrome\Application"
$uninstallKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\Google Chrome"
$appdataTest = test-path -path $appdata
$regKey = test-path -path $uninstallKey

try {
    if(($regKey) -or ($appdataTest)){
        write-host Detected
        # Use the newest version's installer, as an update can leave more than one version folder
        $installer = Get-ChildItem -Path "$appdata\*\Installer\setup.exe" -ErrorAction SilentlyContinue |
            Sort-Object { $_.Directory.Parent.Name -as [version] } -Descending |
            Select-Object -First 1
        if ($installer) {
            & $installer.FullName --uninstall --force-uninstall
        } else {
            # Installer is gone, so clear the leftover folder and uninstall entry so detection passes
            remove-item -Path $appdata, $uninstallKey -Force -Recurse -ErrorAction SilentlyContinue
        }
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
