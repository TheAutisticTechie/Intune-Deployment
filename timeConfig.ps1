$NtpServer = (Get-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters\).NtpServer
$type = (Get-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters\).Type
$service = get-service -name "Windows Time"

if ($NtpServer -ne "time.cloudflare.com,0x9") {
    Set-ItemProperty -Path Registry::"HKLM\SYSTEM\CurrentControlSet\Services\W32Time\Parameters" -Name "NtpServer" -Type "String" -Value "time.cloudflare.com,0x9" -Force
}

if ($type -ne "NTP") {
    Set-ItemProperty -Path Registry::"HKLM\SYSTEM\CurrentControlSet\Services\W32Time\Parameters" -Name "Type" -Type "String" -Value "NTP" -Force
}

if ($service.Status -ne "Running") {
    Start-Service $service
}

w32tm /resync
