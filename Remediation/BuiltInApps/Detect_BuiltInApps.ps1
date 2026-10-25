#=============================================================================================================================
#
# Script Name:      Detect_BuiltInApps.ps1
# Description:      Detects if specific built-in apps are installed
# Author:           Danny Chrismas - TheAutisticTechie
#
#=============================================================================================================================

# Intune runs remediation scripts in 32-bit PowerShell unless "Run script in 64-bit PowerShell" is enabled.
# Relaunch in the native host so the Appx and DISM cmdlets act on the real OS
if ($env:PROCESSOR_ARCHITEW6432 -and (Test-Path "$env:SystemRoot\SysNative\WindowsPowerShell\v1.0\powershell.exe")) {
    & "$env:SystemRoot\SysNative\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File $PSCommandPath
    exit $LASTEXITCODE
}

# Keep in sync with Remediate_BuiltInApps.ps1
# Do not add Microsoft.XboxGameCallableUI - it is part of Windows and cannot be removed, so detection would never pass
# Do not add MSTeams - on Windows 11 23H2+ it is both Teams (free) and new Teams for work or school
$apps = @(
    "DellInc.DellSupportAssistforPCs"
    "Microsoft.Microsoft3DViewer"
    "Microsoft.MicrosoftSolitaireCollection"
    "Microsoft.NetworkSpeedTest"
    "Microsoft.People"
    "Microsoft.SkypeApp"
    "MicrosoftTeams"
    "Microsoft.WindowsAlarms"
    "Microsoft.windowscommunicationsapps"
    "Microsoft.WindowsMaps"
    "Microsoft.XboxApp"
    "Microsoft.GamingApp" # Windows 11 replacement for Microsoft.XboxApp
    "Microsoft.Xbox.TCUI"
    "Microsoft.XboxGameOverlay"
    "Microsoft.XboxGamingOverlay"
    "Microsoft.XboxIdentityProvider"
    "Microsoft.XboxSpeechToTextOverlay"
    # Sponsored
    "*Duolingo-LearnLanguagesforFree*"
    "*PandoraMediaInc*"
    "*CandyCrush*"
    "*BubbleWitch3Saga*"
    "*Wunderlist*"
    "*Flipboard*"
    "*Minecraft*"
    "*RoyalRevolt*"
    "*Speedtest*"
    "*Dolby*"
)

try {
    $provisioned = Get-AppxProvisionedPackage -Online -ErrorAction Stop

    $found = foreach ($app in $apps) {
        # Ignore packages Windows marks as non-removable, as remediation can never clear them
        $installed = Get-AppxPackage -Name $app -AllUsers -ErrorAction Stop | Where-Object { -not $_.NonRemovable }
        if ($installed -or ($provisioned | Where-Object DisplayName -like $app)) {
            $app
        }
    }

    if ($found) {
        Write-Host "Detected: $($found -join ', ')"
        exit 1
    }
    Write-Host "Not Detected"
    exit 0
}
catch {
    $errMsg = $_.Exception.Message
    Write-Error $errMsg
    exit 1
}
