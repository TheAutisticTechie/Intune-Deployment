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
$key = ""
$group = ""
$downloadA32 = "NessusAgent-32.msi"
$downloadA64 = "NessusAgent-64.msi"
$downloadS32 = "Nessus-32.msi"
$downloadS64 = "Nessus-64.msi"
$blob = "https://#####.blob.core.windows.net/scriptfiles/"

# Do not change
$temp = "c:\temp"
$testTemp = Test-Path -Path $temp -PathType Container
$destA = "c:\temp\NessusAgent.msi"
$destS = "c:\temp\Nessus.msi"
$testDestA = Test-Path -Path $destA -PathType Leaf
$testDestS = Test-Path -Path $destS -PathType Leaf
$logPath = Join-path -path $($env:SystemRoot) -ChildPath "\TEMP\log_NessusAgentInstall.txt"
$arch = (Get-CimInstance Win32_operatingsystem).OSArchitecture
$ErrorActionPreference = "stop"
### END Variables ###

Start-Transcript $logPath -append -Force
Write-Output ""
Write-Output ""
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
            Invoke-WebRequest -Uri $agentsrc -OutFile $destA
            Start-Sleep -Seconds 30
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
            Invoke-WebRequest -Uri $scannersrc -OutFile $destS
            Start-Sleep -Seconds 30
        }
        catch {
            throw $_.Exception.Message
        }
    }

    # Install Agent
    if ($testDestA) {
        try {
            Write-Output "Beginning the Agent install, please do not shut down the computer for at least 10 minutes"
            msiexec.exe /i \temp\NessusAgent.msi /qn
            Start-Sleep -Seconds 120
            if ($arch -eq "64-bit") {
                set-location 'C:\Program Files\Tenable\Nessus Agent\'
            } else {
                set-location 'C:\Program Files (x86)\Tenable\Nessus\'
            }
            .\nessuscli agent link --key=$key --cloud --groups=$group

        }
        catch {
            throw $_.Exception.Message
        }
    }

    # Install Scanner
    if ($scanner -eq $true -and $testDestS) {
        try {
            Write-Output "Beginning the Scanner install, please do not shut down the computer"
            c:\temp\Nessus.msi /qn
            Write-Output "The Scanner is still being installed, please wait."
            Start-Sleep -Seconds 120
            if ($arch -eq "64-bit") {
                set-location 'C:\Program Files\Tenable\Nessus\'
            } else {
                set-location 'C:\Program Files (x86)\Tenable\Nessus\'
            }
            Stop-Service -Name "Tenable Nessus"
            .\nessuscli managed link --key=$key --cloud
            Start-Service -Name "Tenable Nessus"
        }
        catch {
            throw $_.Exception.Message
        }
    }

    # Cleanup
    Write-Output "Cleaning up after the script, almost finished"
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
    Start-Sleep -Seconds 10
    Write-Output "Completed"
    Write-Output ""
    Write-Output ""
}
catch {
    Write-Host "An error has occurred"
}
finally {
    $ErrorActionPreference = "continue"
    Stop-Transcript
}
