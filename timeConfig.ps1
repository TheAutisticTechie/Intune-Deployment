<#
.SYNOPSIS
    Sets Cloudflare as the NTP server
.DESCRIPTION
    (c) Danny Murphy. All rights reserved.
    Script provided as-is without any warranty of any kind. Use it freely at your own risks.
    Must be run with elevated permissions. 
    Designed to be run as user assigned PowerShell Script from Intune
    The script will set Cloudflare as the time source
    Requires PowerShell 3.0.
.INPUTS
  None
.OUTPUTS
  Log file stored in %SystemDrive%\Windows\TEMP\log_Update-timeConfig.txt
.NOTES
  Version:          2.0
  Author:           Danny Murphy
  Twitter:          @dltmurphy
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
$NtpServer = (Get-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters\).NtpServer
$type = (Get-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters\).Type
$service = get-service -name "Windows Time"
$logPath = Join-path -path $($env:SystemRoot) -ChildPath "\TEMP\log_timeConfig.txt"

Start-Transcript $logPath -Force

try {
    w32tm /config /manualpeerlist:"time.cloudflare.com,0x1" /syncfromflags:MANUAL /update
    try {
        if ($service.Status -ne "Running") {
            Start-Service "Windows Time"
            return
        } else {
            Restart-Service "Windows Time"
            return
        }
    }
    catch [SystemException] {
        write-host "Error processing Windows Time service."
    }
    w32tm /resync
    try {
        if ($NtpServer -ne "time.cloudflare.com,0x1") {
            Set-ItemProperty -Path Registry::"HKLM\SYSTEM\CurrentControlSet\Services\W32Time\Parameters" -Name "NtpServer" -Type "String" -Value "time.cloudflare.com,0x1" -Force
            return
        }
    }
    catch [System.Management.Automation.PSArgumentException] {
        Write-Host "Unable to write to registry"
    }
    try {
        if ($type -ne "NTP") {
            Set-ItemProperty -Path Registry::"HKLM\SYSTEM\CurrentControlSet\Services\W32Time\Parameters" -Name "Type" -Type "String" -Value "NTP" -Force
            return
        }
    }
    catch [System.Management.Automation.PSArgumentException] {
        Write-Host "Unable to write to registry"
    }
    try {
        if ($service.StartType -ne "Automatic" ) {
            Set-Service w32time -StartupType "Automatic"
            return
        }
    }
    catch [SystemException] {
        Write-Host "Error processing Windows Time service."
    }
    try {
        if ($service.Status -ne "Running") {
            Start-Service "Windows Time"
            return
        } else {
            Restart-Service "Windows Time"
            return
        }
    }
    catch [SystemException] {
        write-host "Error processing Windows Time service."
    }
}
catch {
    Write-Host "An error has occurred"
}
finally {
    $ErrorActionPreference = "continue"
    Stop-Transcript
    w32tm /resync
}
