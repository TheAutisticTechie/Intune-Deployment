#=============================================================================================================================
#
# Script Name:      Detect_Uptime.ps1
# Description:      Detects if the device hasn't restarted for too many days
#                   Run using the logged-on credentials, so Remediate_Uptime.ps1 can notify the user
# Author:           Danny Chrismas - TheAutisticTechie
#
#=============================================================================================================================

# Variables
$maxDays = 7
$markerKey = "HKCU:\Software\Intune-Deployment\Uptime"

try {
    $lastBoot = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
    $uptime = (Get-Date) - $lastBoot

    if ($uptime.TotalDays -lt $maxDays) {
        Write-Host "Uptime: $($uptime.Days) days"
        exit 0
    }

    # Remediate_Uptime.ps1 has already scheduled a restart since this boot, so don't remind again until it's due
    $marker = Get-ItemProperty -Path $markerKey -ErrorAction SilentlyContinue
    if ($marker -and ([datetime]$marker.ScheduledAt -gt $lastBoot) -and ([datetime]$marker.RestartAt -gt (Get-Date))) {
        Write-Host "Uptime: $($uptime.Days) days - restart scheduled for $($marker.RestartAt)"
        exit 0
    }

    Write-Host "Uptime: $($uptime.Days) days - restart needed"
    exit 1
}
catch {
    $errMsg = $_.Exception.Message
    Write-Error $errMsg
    exit 1
}
