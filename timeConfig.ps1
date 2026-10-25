<#
.SYNOPSIS
    Sets Cloudflare as the NTP server
.DESCRIPTION
    (c) Danny Chrismas. All rights reserved.
    Script provided as-is without any warranty of any kind. Use it freely at your own risks.
    Must be run with elevated permissions.
    Designed to be run as a SYSTEM PowerShell Script from Intune
    The script will set Cloudflare as the time source
    Requires PowerShell 3.0.
.INPUTS
  None
.OUTPUTS
  Log file stored in %SystemDrive%\Windows\TEMP\log_timeConfig.txt
.NOTES
  Version:          2.0
  Author:           Danny Chrismas
  Twitter:          @theautistictechie
  Creation Date:    19 September 2021
  Purpose/Change:   Intune managed devices with Cloudflare as the time source
.EXAMPLE
  .\timeConfig.ps1
  Run as an administator or SYSTEM
#>

#Requires -Version 3
#Requires -Runasadministrator

# Stop if error
$ErrorActionPreference = "stop"

# Variables
$configKey = "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Config"
$ntpClientKey = "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\NtpClient"
$logPath = Join-path -path $($env:SystemRoot) -ChildPath "\TEMP\log_timeConfig.txt"

# W32Time uses different units per setting:
#   MinPollInterval and MaxPollInterval are log2 seconds, so 6 = 64 seconds
#   SpecialPollInterval is seconds, and must sit between MinPollInterval and MaxPollInterval
#   UpdateInterval is 10ms units, so 100 = 1 second
$settings = @(
    @{ Path = $configKey;    Name = "FrequencyCorrectRate"; Value = 2 }
    @{ Path = $configKey;    Name = "MinPollInterval";      Value = 6 }
    @{ Path = $configKey;    Name = "MaxPollInterval";      Value = 6 }
    @{ Path = $configKey;    Name = "UpdateInterval";       Value = 100 }
    @{ Path = $ntpClientKey; Name = "SpecialPollInterval";  Value = 64 }
)

Start-Transcript $logPath -Force

try {
    foreach ($setting in $settings) {
        $current = (Get-ItemProperty -Path $setting.Path).($setting.Name)
        if ($current -ne $setting.Value) {
            Write-Host "Setting $($setting.Name) from $current to $($setting.Value)"
            Set-ItemProperty -Path $setting.Path -Name $setting.Name -Value $setting.Value -Type DWord
        }
    }

    $service = Get-Service -Name "W32Time"
    if ($service.StartType -ne "Automatic") {
        Set-Service -Name "W32Time" -StartupType Automatic
    }
    if ($service.Status -ne "Running") {
        Start-Service -Name "W32Time"
    }

    # Sets NtpServer and Type to NTP, then tells the service to reload all of the settings above
    w32tm /config /manualpeerlist:"time.cloudflare.com,0x1" /syncfromflags:MANUAL /update
    w32tm /resync
}
catch {
    Write-Host "An error has occurred: $($_.Exception.Message)"
    exit 1
}
finally {
    Stop-Transcript
}
