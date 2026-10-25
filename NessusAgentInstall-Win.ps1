<#
.SYNOPSIS
    Installs and configures the Nessus Agent for x64 or x86 architecture
.DESCRIPTION
    (c) Danny Chrismas. All rights reserved.
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
  Author:           Danny Chrismas
  Twitter:          @theautistictechie
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
$destA = "c:\temp\NessusAgent.msi"
$destS = "c:\temp\Nessus.msi"
$logPath = Join-path -path $($env:SystemRoot) -ChildPath "\TEMP\log_NessusAgentInstall.txt"
# Native architecture (AMD64, x86 or ARM64), even when Intune runs this in 32-bit PowerShell
$arch = if ($env:PROCESSOR_ARCHITEW6432) { $env:PROCESSOR_ARCHITEW6432 } else { $env:PROCESSOR_ARCHITECTURE }
# ProgramW6432 is the 64-bit Program Files even from 32-bit PowerShell, and is unset on 32-bit Windows
$programFiles = if ($env:ProgramW6432) { $env:ProgramW6432 } else { $env:ProgramFiles }
$ErrorActionPreference = "stop"
# The progress bar makes Invoke-WebRequest very slow in Windows PowerShell
$ProgressPreference = "SilentlyContinue"
### END Variables ###

function Get-Installer($src, $dest) {
    # Download from a URL, or copy from a file share
    if ($src -match '^https?://') {
        Invoke-WebRequest -Uri $src -OutFile $dest -UseBasicParsing
    } else {
        Copy-Item -Path $src -Destination $dest
    }
}

function Install-Msi($msi) {
    # msiexec returns straight away when called directly, so wait for it and check the result
    $process = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$msi`" /qn" -Wait -PassThru
    # 1638 = another version is already installed, 3010 = installed but needs a restart
    if ($process.ExitCode -notin 0, 1638, 3010) {
        throw "msiexec failed for $msi with exit code $($process.ExitCode)"
    }
}

Start-Transcript $logPath -append -Force
Write-Output ""
Write-Output ""
try {
    switch ($arch) {
        "AMD64" { $agentFile = $downloadA64; $scannerFile = $downloadS64 }
        "x86"   { $agentFile = $downloadA32; $scannerFile = $downloadS32 }
        default { throw "Unsupported architecture: $arch - add an installer for it to this script" }
    }

    # Check temp folder exists, create it if not
    $cleanTemp = $False
    if (-not (Test-Path -Path $temp -PathType Container)) {
        New-Item -path $temp -ItemType Directory | Out-Null
        $cleanTemp = $True
    }

    # Download Agent, unless it has already been staged
    if (-not (Test-Path -Path $destA -PathType Leaf)) {
        if (!$agentsrc) {
            $agentsrc = $blob + $agentFile
        }
        Write-Output "Downloading the Agent"
        Get-Installer $agentsrc $destA
    }

    # Download Scanner, unless it has already been staged
    if ($scanner -and -not (Test-Path -Path $destS -PathType Leaf)) {
        if (!$scannersrc) {
            $scannersrc = $blob + $scannerFile
        }
        Write-Output "Downloading the Scanner"
        Get-Installer $scannersrc $destS
    }

    # Install Agent
    Write-Output "Beginning the Agent install, please do not shut down the computer"
    Install-Msi $destA
    & "$programFiles\Tenable\Nessus Agent\nessuscli.exe" agent link --key=$key --cloud --groups=$group
    Write-Output "Agent link exited with code $LASTEXITCODE"

    # Install Scanner
    if ($scanner) {
        Write-Output "Beginning the Scanner install, please do not shut down the computer"
        Install-Msi $destS
        Stop-Service -Name "Tenable Nessus"
        & "$programFiles\Tenable\Nessus\nessuscli.exe" managed link --key=$key --cloud
        Write-Output "Scanner link exited with code $LASTEXITCODE"
        Start-Service -Name "Tenable Nessus"
    }

    # Cleanup
    Write-Output "Cleaning up after the script, almost finished"
    if ($cleanTemp) {
        Remove-Item $temp -recurse -force
    } else {
        Remove-Item $destA, $destS -Force -ErrorAction SilentlyContinue
    }
    Write-Output "Completed"
    Write-Output ""
    Write-Output ""
}
catch {
    Write-Output "An error has occurred: $($_.Exception.Message)"
    exit 1
}
finally {
    $ErrorActionPreference = "continue"
    Stop-Transcript
}
