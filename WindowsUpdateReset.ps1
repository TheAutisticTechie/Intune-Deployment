<#
.SYNOPSIS
    Reset Windows Update Services to Microsoft's CDN
.DESCRIPTION
    (c) Danny Murphy. All rights reserved.
    Script provided as-is without any warranty of any kind. Use it freely at your own risks.
    Must be run with elevated permissions. 
    Designed to be run as a SYSTEM PowerShell Script from Intune
    The script will reset WSUS to Microsoft
    Requires PowerShell 3.0.
.INPUTS
  None
.OUTPUTS
  None
.NOTES
  Version:          2.0
  Author:           Danny Chrismas @TheAutisticTechie
  Creation Date:    19 September 2021
  Purpose/Change:   Reset Windows Update Services to Microsoft's CDN
.EXAMPLE
  .\windowsUpdateReset.ps1
  Run as an administator or SYSTEM
#>

#Requires -Version 3
#Requires -Runasadministrator

$reg = "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate"

if (Test-Path $reg) {
	Stop-Service -Name wuauserv
	Remove-Item $reg -Recurse
	Start-Service -Name wuauserv
}
