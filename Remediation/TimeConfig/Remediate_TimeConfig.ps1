<#
.SYNOPSIS
    Sets Cloudflare as the NTP server
.DESCRIPTION
    (c) Danny Chrismas. Licensed under the MIT License, see LICENSE.
    Script provided as-is without any warranty of any kind. Use it freely at your own risks.
    Must be run with elevated permissions.
    Designed to be run as an Intune Remediation in the SYSTEM context, with Detect_TimeConfig.ps1 as the detection script
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
  .\Remediate_TimeConfig.ps1
  Run as an administator or SYSTEM
#>

#Requires -Version 3
#Requires -Runasadministrator

# Intune runs scripts in 32-bit PowerShell unless "Run script in 64 bit PowerShell Host" is enabled. Relaunch in the
# native host so w32tm and sc run as their native versions
if ($env:PROCESSOR_ARCHITEW6432 -and (Test-Path "$env:SystemRoot\SysNative\WindowsPowerShell\v1.0\powershell.exe")) {
    & "$env:SystemRoot\SysNative\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File $PSCommandPath
    exit $LASTEXITCODE
}

# Stop if error
$ErrorActionPreference = "stop"

# Variables - keep in sync with Detect_TimeConfig.ps1
# 0x9 = Client (0x8) + SpecialInterval (0x1), the same flags as Windows' default of time.windows.com,0x9
$ntpServer = "time.cloudflare.com,0x9"
$parametersKey = "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters"
$configKey = "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Config"
$ntpClientKey = "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\NtpClient"
$policyKey = "HKLM:\SOFTWARE\Policies\Microsoft\W32Time"
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
    @{ Path = $ntpClientKey; Name = "Enabled";              Value = 1 }
)

Start-Transcript $logPath -Force

try {
    # Group Policy or an Intune Windows Time Service policy overrides the local settings this script makes, so stop if
    # one sets a different time source or turns the NTP client off
    $policyParameters = Get-ItemProperty -Path "$policyKey\Parameters" -ErrorAction SilentlyContinue
    $policyNtpClient = Get-ItemProperty -Path "$policyKey\TimeProviders\NtpClient" -ErrorAction SilentlyContinue
    if (($policyParameters.NtpServer -and ($policyParameters.NtpServer -notlike "time.cloudflare.com*")) -or
        ($policyParameters.Type -and ($policyParameters.Type -ne "NTP")) -or
        ($policyNtpClient.Enabled -eq 0)) {
        throw "A Group Policy or Intune policy configures the Windows Time service and overrides this script " +
            "(NtpServer: $($policyParameters.NtpServer), Type: $($policyParameters.Type), NtpClient Enabled: $($policyNtpClient.Enabled))"
    }
    if (Test-Path "$policyKey\Config") {
        Write-Host "Warning: a policy sets the Windows Time Config values, so the poll intervals below may not apply"
    }

    foreach ($setting in $settings) {
        $current = (Get-ItemProperty -Path $setting.Path).($setting.Name)
        if ($current -ne $setting.Value) {
            Write-Host "Setting $($setting.Name) from $current to $($setting.Value)"
            Set-ItemProperty -Path $setting.Path -Name $setting.Name -Value $setting.Value -Type DWord
        }
    }

    # On devices that aren't joined to an AD domain, including Entra-joined laptops, Windows' default trigger stops this
    # service straight after startup, even when it's set to Automatic. Start it whenever the device has a network
    # connection instead, so it keeps syncing (Microsoft KB 2385818, method 2)
    sc.exe triggerinfo w32time start/networkon stop/networkoff
    if ($LASTEXITCODE -ne 0) {
        throw "sc.exe triggerinfo failed with exit code $LASTEXITCODE"
    }

    $service = Get-Service -Name "W32Time"
    if ($service.StartType -ne "Automatic") {
        Set-Service -Name "W32Time" -StartupType Automatic
    }
    if ($service.Status -ne "Running") {
        Start-Service -Name "W32Time"
    }

    # Sets NtpServer and Type to NTP, then tells the service to reload all of the settings above
    w32tm /config /manualpeerlist:"$ntpServer" /syncfromflags:MANUAL /update
    if ($LASTEXITCODE -ne 0) {
        throw "w32tm /config failed with exit code $LASTEXITCODE"
    }

    # Sync now from the new source. This fails if the device is offline or UDP 123 is blocked, so only report it
    w32tm /resync /rediscover
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Warning: w32tm /resync failed with exit code $LASTEXITCODE - the device will sync once it can reach $ntpServer"
    }

    # Confirm the settings Windows will actually use
    $parameters = Get-ItemProperty -Path $parametersKey
    if (($parameters.NtpServer -ne $ntpServer) -or ($parameters.Type -ne "NTP")) {
        throw "Time source is $($parameters.NtpServer) ($($parameters.Type)), not $ntpServer (NTP)"
    }
    Write-Host "Time source set to $($parameters.NtpServer)"
    Write-Host "Source in use: $(w32tm /query /source)"
}
catch {
    Write-Host "An error has occurred: $($_.Exception.Message)"
    exit 1
}
finally {
    Stop-Transcript
}
