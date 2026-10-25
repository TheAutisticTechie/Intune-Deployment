<#
.SYNOPSIS
    Disable Fast Startup
.DESCRIPTION
    (c) Danny Chrismas. Licensed under the MIT License, see LICENSE.
    Script provided as-is without any warranty of any kind. Use it freely at your own risks.
    Must be run with elevated permissions.
    Designed to be run as an Intune Remediation in the SYSTEM context (Run this script using the logged-on credentials: No)
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
  .\Remediate_DisableHiberboot.ps1
  Run as an administator or SYSTEM
#>

#Requires -Version 3
#Requires -Runasadministrator

# Stop if error
$ErrorActionPreference = "stop"

$logPath = Join-path -path $($env:SystemRoot) -ChildPath "\TEMP\log_disableFastStartup.txt"
$powerKey = "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Power\"

# Out-Null keeps the transcript messages out of the Intune output column
Start-Transcript $logPath -Force -Append | Out-Null

try {
    $hiberboot = (Get-ItemProperty -Path $powerKey).HiberbootEnabled
    if ($hiberboot -ne 0) {
        # -Type DWord so a missing value is created as a DWORD rather than a string
        Set-ItemProperty -Path $powerKey -Name "HiberbootEnabled" -Value 0 -Type DWord
        Write-Host "Fast Startup disabled"
    } else {
        Write-Host "Fast Startup already disabled"
    }
    exit 0
}
catch {
    Write-Host "Unable to write to registry: $($_.Exception.Message)"
    exit 1
}
finally {
    # Runs even after exit, so it must not call exit itself or it overrides the exit code above
    Stop-Transcript | Out-Null
}
