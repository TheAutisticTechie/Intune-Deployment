#=============================================================================================================================
#
# Script Name:      Detect_TimeConfig.ps1
# Description:      Detects if the device isn't using Cloudflare as its time source, or if the Windows Time service
#                   won't stay running to sync with it
# Author:           Danny Chrismas - TheAutisticTechie
#
#=============================================================================================================================

# Intune runs remediation scripts in 32-bit PowerShell unless "Run script in 64-bit PowerShell" is enabled. Relaunch in
# the native host so sc runs as its native version
if ($env:PROCESSOR_ARCHITEW6432 -and (Test-Path "$env:SystemRoot\SysNative\WindowsPowerShell\v1.0\powershell.exe")) {
    & "$env:SystemRoot\SysNative\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File $PSCommandPath
    exit $LASTEXITCODE
}

# Variables - keep in sync with Remediate_TimeConfig.ps1
$ntpServer = "time.cloudflare.com,0x9"
$parametersKey = "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters"
$configKey = "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Config"
$ntpClientKey = "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\NtpClient"
$policyKey = "HKLM:\SOFTWARE\Policies\Microsoft\W32Time"
$settings = @(
    @{ Path = $configKey;    Name = "FrequencyCorrectRate"; Value = 2 }
    @{ Path = $configKey;    Name = "MinPollInterval";      Value = 6 }
    @{ Path = $configKey;    Name = "MaxPollInterval";      Value = 6 }
    @{ Path = $configKey;    Name = "UpdateInterval";       Value = 100 }
    @{ Path = $ntpClientKey; Name = "SpecialPollInterval";  Value = 64 }
    @{ Path = $ntpClientKey; Name = "Enabled";              Value = 1 }
)
# Windows' default trigger that stops the service on devices that aren't joined to an AD domain
$notDomainJoinedTrigger = "ddaf516e-58c2-4866-9574-c3b615d42ea1"

try {
    $issues = @()

    $policyParameters = Get-ItemProperty -Path "$policyKey\Parameters" -ErrorAction SilentlyContinue
    $policyNtpClient = Get-ItemProperty -Path "$policyKey\TimeProviders\NtpClient" -ErrorAction SilentlyContinue
    if (($policyParameters.NtpServer -and ($policyParameters.NtpServer -notlike "time.cloudflare.com*")) -or
        ($policyParameters.Type -and ($policyParameters.Type -ne "NTP")) -or
        ($policyNtpClient.Enabled -eq 0)) {
        $issues += "a Group Policy or Intune policy overrides the time settings"
    }

    $parameters = Get-ItemProperty -Path $parametersKey
    if ($parameters.NtpServer -ne $ntpServer) {
        $issues += "NtpServer is $($parameters.NtpServer)"
    }
    if ($parameters.Type -ne "NTP") {
        $issues += "Type is $($parameters.Type)"
    }

    foreach ($setting in $settings) {
        $current = (Get-ItemProperty -Path $setting.Path).($setting.Name)
        if ($current -ne $setting.Value) {
            $issues += "$($setting.Name) is $current"
        }
    }

    if ((Get-Service -Name "W32Time").StartType -ne "Automatic") {
        $issues += "W32Time isn't set to Automatic"
    }
    $triggers = sc.exe qtriggerinfo w32time | Out-String
    if ($LASTEXITCODE -ne 0) {
        $issues += "couldn't read the W32Time triggers"
    } elseif ($triggers -match $notDomainJoinedTrigger) {
        $issues += "W32Time still stops on devices that aren't domain joined"
    }

    if ($issues) {
        Write-Host "Not compliant: $($issues -join ', ')"
        exit 1
    }
    Write-Host "Compliant: $ntpServer"
    exit 0
}
catch {
    $errMsg = $_.Exception.Message
    Write-Error $errMsg
    exit 1
}
