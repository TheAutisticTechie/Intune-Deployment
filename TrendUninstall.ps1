#=============================================================================================================================
#
# Script Name:      TrendUninstall.ps1
# Description:      Downloads and runs Trend Micro's uninstall tool to force uninstall the Security Agent
# Author:           Danny Chrismas - TheAutisticTechie
#
#=============================================================================================================================

# ARCHIVED - kept for reference, not for deployment. Uses Trend Micro's Worry-Free Business Security Agent uninstall
# tool in the TrendMicroUninstall folder (with TrendMicroUninstall.bat as a standalone copy of its Uninstall.bat)

# Zip the contents of the TrendMicroUninstall folder and upload it to storage you control, then set its HTTPS URL and
# SHA256 hash below. Get the hash with: (Get-FileHash .\TrendMicroUninstall.zip).Hash
$url = "https://delltechcentre.com/TrendMicroUninstall.zip"
$expectedHash = ""
$installerPath = "C:\TrendUninstallTemp"
$file = "TrendMicroUninstall.zip"
$uninstallFile = "Uninstall.bat"
$path = $installerPath + "\" + $File
$scriptUninstallPath = "$installerPath" + "\" + "$uninstallFile"

# Check if Trend micro is already installed on the computer
$installCheck = Join-Path ([System.Environment]::GetFolderPath("ProgramFilesx86")) "Trend Micro\Security Agent\PccNTMon.exe"

# Try downloading and running as long as the PccNTMon.exe isn't in the "Program Files" folder
if(Test-Path $installCheck) {
     try {
        # This runs as SYSTEM, so only run a download that came over HTTPS and matches the expected hash
        if (($url -notlike "https://*") -or (!$expectedHash)) {
            Throw "Set an HTTPS url and the zip's SHA256 expectedHash before deploying"
        }

        # Create directory to download the zip file, fail if it can't create it
        if (!(Test-Path -PathType Container -Path $installerPath)) {
            Try {
                New-Item $installerPath -ItemType Directory -ErrorAction Stop
            }
            Catch {
                Throw "Failed to create Temp Directory"
            }
        }
        $down = New-Object System.Net.WebClient
        $down.DownloadFile($url,$path)
        if ((Get-FileHash -Path $path -Algorithm SHA256).Hash -ne $expectedHash) {
            Remove-Item $path -Force
            Throw "Downloaded zip does not match the expected hash - not running it"
        }
        #Extract the zip contents
        Expand-Archive -Path $path -DestinationPath $installerPath -Force
        & $scriptUninstallPath
     }
     catch {
         Throw "Failed to run script: $($_.Exception.Message)"
     }
}
