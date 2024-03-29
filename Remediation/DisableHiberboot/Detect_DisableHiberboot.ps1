<#
.SYNOPSIS
    Disable Fast Startup
.DESCRIPTION
    (c) Danny Chrismas. All rights reserved.
    Script provided as-is without any warranty of any kind. Use it freely at your own risks.
    Must be run with elevated permissions. 
    Designed to be run as user assigned PowerShell Script from Intune
    The script will disable fast startup
    Requires PowerShell 3.0.
.INPUTS
  None
.OUTPUTS
  Log file stored in %SystemDrive%\Windows\TEMP\log_disableFastStartup.txt
.NOTES
  Version:          2.0
  Author:           Danny Chrismas
  Twitter:          @TheAutisticTech
  Creation Date:    19 September 2021
  Purpose/Change:   Disable fast startup on Intune connected Windows devices
.EXAMPLE
  .\disableFastStartup.ps1
  Run as an administator or SYSTEM
#>

#Requires -Version 3
#Requires -Runasadministrator

# Stop if error
$ErrorActionPreference = "stop"

$logPath = Join-path -path $($env:SystemRoot) -ChildPath "\TEMP\log_disableFastStartup.txt"
$hiberboot = (Get-ItemProperty -Path Registry::"HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Power\").HiberbootEnabled

Start-Transcript $logPath -Force

try {
  if ($hiberboot -ne "0") {
    exit 1 # Incorrect
  } else {
    exit 0
  }
} 
catch [System.Management.Automation.PSArgumentException] {
  Write-Host "Unable to write to registry"
  exit 1
}
finally {
    $ErrorActionPreference = "continue"
    Write-Host "Unknown Error"
    exit 1
    Stop-Transcript
}

