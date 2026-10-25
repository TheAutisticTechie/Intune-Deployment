#=============================================================================================================================
#
# Script Name:      Remediate_BuiltInApps.ps1
# Description:      Uninstall specific built-in apps
# Author:           Danny Chrismas - TheAutisticTechie
#
#=============================================================================================================================

# Intune runs remediation scripts in 32-bit PowerShell unless "Run script in 64-bit PowerShell" is enabled.
# Relaunch in the native host so the Appx and DISM cmdlets act on the real OS
if ($env:PROCESSOR_ARCHITEW6432 -and (Test-Path "$env:SystemRoot\SysNative\WindowsPowerShell\v1.0\powershell.exe")) {
    & "$env:SystemRoot\SysNative\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File $PSCommandPath
    exit $LASTEXITCODE
}

# Keep in sync with Detect_BuiltInApps.ps1
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

$failed = @()

try {
    $provisioned = Get-AppxProvisionedPackage -Online -ErrorAction Stop

    foreach ($app in $apps) {
        try {
            # Windows 11 installs Store-updated apps as bundles, and Remove-AppxPackage -AllUsers only works on the
            # parent package. Remove bundles first, then any standalone packages that are left
            foreach ($type in "Bundle", "Main") {
                Get-AppxPackage -Name $app -AllUsers -PackageTypeFilter $type -ErrorAction Stop |
                    Where-Object { -not $_.NonRemovable } |
                    ForEach-Object { Remove-AppxPackage -Package $_.PackageFullName -AllUsers -ErrorAction Stop }
            }

            $provisioned | Where-Object DisplayName -like $app |
                ForEach-Object { Remove-AppxProvisionedPackage -Online -AllUsers -PackageName $_.PackageName -ErrorAction Stop | Out-Null }
        } catch {
            Write-Host "Error uninstalling $app : $($_.Exception.Message)"
            $failed += $app
        }
    }

    if ($failed) {
        Write-Host "Failed: $($failed -join ', ')"
        exit 1
    }
    Write-Host "Built-in apps removed"
    exit 0
}
catch {
    $errMsg = $_.Exception.Message
    Write-Error $errMsg
    exit 1
}
