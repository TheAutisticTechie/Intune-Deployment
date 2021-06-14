# Stop if error
$ErrorActionPreference = "stop"

# Variables
$NtpServer = (Get-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters\).NtpServer
$type = (Get-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters\).Type
$service = get-service -name "Windows Time"

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
    w32tm /resync
}