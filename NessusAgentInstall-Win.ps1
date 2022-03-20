<#
.SYNOPSIS
    Installs and configures the Nessus Agent for x64 or x86 architecture
.DESCRIPTION
    (c) Danny Murphy. All rights reserved.
    Script provided as-is without any warranty of any kind. Use it freely at your own risks.
    Must be run with elevated permissions. 
    The script will install and configure the correct Nessus Agent for the device's architecture
    Requires PowerShell 3.0.
.INPUTS
  -scanner to install the Nessus Scanner at the same time.
  -agentsrc to specify a source file for the agent install
  -scannerc to specify a source file for the scanner install
.OUTPUTS
  Log file stored in %SystemDrive%\Windows\TEMP\log_NessusAgentInstall.txt
.NOTES
  Version:          1.0
  Author:           Danny Murphy
  Twitter:          @dltmurphy
  Creation Date:    20 March 2022
  Purpose/Change:   Install and configure Nessus Agents for specific architecture automatically
.EXAMPLE
  .\NessusAgentInstall-Win.ps1
  Run as an administator to install and configure Nessus Agent

  .\NessusAgentInstall-Win.ps1 -scanner
  Run as an administator to install and configure Nessus Agent and Nessus Scanner

  .\NessusAgentInstall-Win.ps1 -scanner -scannersrc \\server\share\nessus.msi -agentsrc \\server\share\nessusagent.msi
  Run as an administator to install and configure Nessus Agent and Nessus Scanner using a share as the source
#>

#Requires -Version 3
#Requires -Runasadministrator

### Parameters
Param (
    [Parameter(Mandatory=$False)]
    [switch]$scanner,
    [Parameter(Mandatory=$False)]
    [string]$agentsrc = $null,
    [Parameter(Mandatory=$False)]
    [string]$scannersrc = $null
    )

### Variables ###
# Change these #
$linkingKey = ""
$group = ""
$downloadA32 = "NessusAgent-32.msi"
$downloadA64 = "NessusAgent-64.msi"
$downloadS32 = "Nessus-32.msi"
$downloadS64 = "Nessus-64.msi"
$blob = "https://######.blob.core.windows.net/scriptfiles/"

# Do not change
$temp = "c:\temp"
$testTemp = Test-Path -Path $temp -PathType Container
$destA = "c:\temp\NessusAgent.msi"
$destS = "c:\temp\Nessus.msi"
$testDestA = Test-Path -Path $destA -PathType Leaf
$testDestS = Test-Path -Path $destS -PathType Leaf
$logPath = Join-path -path $($env:SystemRoot) -ChildPath "\TEMP\log_NessusAgentInstall.txt"
$arch = (Get-CimInstance Win32_operatingsystem).OSArchitecture
$key= "NESSUS_KEY='" + $linkingKey + "'"
$groups = "NESSUS_GROUPS='" + $group + "'"
$server = "NESSUS_SERVER='cloud.tenable.com:443'"
$msiArgsA = @(
    "/i"
    "$destA"
    "$server"
    "$key"
    "$groups"
    "/qn"
)
$msiArgsS = @(
    "/i"
    "$destS"
    "$server"
    "$key"
    "$groups"
    "/qn"
)
$ErrorActionPreference = "stop"
### END Variables ###

Start-Transcript $logPath -append -Force
try {
    # Check temp folder exists, create it if not
    if (!$agentsrc) {
        if (-not($testTemp)) {
            try {
                New-Item -path $temp -ItemType Directory
                $cleanTemp = $True
            }
            catch {
                throw $_.Exception.Message
            }
        } else {
            $cleanTemp = $False
        }
    }

    # Download Agent
    if ($arch -eq "64-bit") {
        if (!$agentsrc) {
            $agentsrc = $blob + $downloadA64
        }
    }
    if ($arch -eq "32-bit") {
        if (!$agentsrc) {
            $agentsrc = $blob + $downloadA32
        }
    }
    if (-not($testDestA)) {
        try {
            Write-Output "Downloading the Agent"
            Start-BitsTransfer -Source $agentsrc -Destination $destA
        }
        catch {
            throw $_.Exception.Message
        }
    }

    # Download Scanner
    if ($scanner -eq $True -and -not($testDestS)) {
        if (!$scannersrc -and $arch -eq "64-bit") {
            $scannersrc = $blob + $downloadS64
        }
        if (!$scannersrc -and $arch -eq "32-bit") {
            $scannersrc = $blob + $downloadS32
        }
        
        try {
            Write-Output "Downloading the Scanner"
            Start-BitsTransfer -Source $scannersrc -Destination $destS
        }
        catch {
            throw $_.Exception.Message
        }
    }

    # Install Agent
    if ($testDestA) {
        try {
            Write-Output "Beginning the Agent install, please do not shut down the computer"
            Start-Process "msiexec.exe" -ArgumentList $msiArgsA -wait -NoNewWindow
            Write-Output "The Agent is still being installed, please keep the device on for at least another 10 minutes"
        }
        catch {
            throw $_.Exception.Message
        }
    }

    # Install Scanner
    if ($scanner -eq $true -and $testDestS) {
        try {
            Write-Output "Beginning the Scanner install, please do not shut down the computer"
            Start-Process "msiexec.exe" -ArgumentList $msiArgsS -wait -NoNewWindow
            Write-Output "The Scanner is still being installed, please keep the device on for at least another 10 minutes"
        }
        catch {
            throw $_.Exception.Message
        }
    }

    # Cleanup
    if ($cleanTemp -eq $true) {
        try {
            Remove-Item $temp -recurse -force
        }
        catch {
            throw $_.Exception.Message
        }
    }
    else {
        try {
            if ($testDestA) {
                Remove-Item $destA
            }
            if ($testDestS) {
                Remove-Item $destS
            }
        }
        catch {
            throw $_.Exception.Message
        }
    }
}
catch {
    Write-Host "An error has occurred"
}
finally {
    $ErrorActionPreference = "continue"
    Stop-Transcript
}
