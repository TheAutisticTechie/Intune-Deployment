$NtpServer = (Get-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters\).NtpServer
$type = (Get-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters\).Type
$service = get-service -name "Windows Time"

w32tm /config /manualpeerlist:"time.cloudflare.com,0x4" /syncfromflags:MANUAL /update

if ($NtpServer -ne "time.cloudflare.com,0x9") {
    Set-ItemProperty -Path Registry::"HKLM\SYSTEM\CurrentControlSet\Services\W32Time\Parameters" -Name "NtpServer" -Type "String" -Value "time.cloudflare.com,0x4" -Force
}

if ($type -ne "NTP") {
    Set-ItemProperty -Path Registry::"HKLM\SYSTEM\CurrentControlSet\Services\W32Time\Parameters" -Name "Type" -Type "String" -Value "NTP" -Force
}

if ($service.StartType -ne "Automatic" {
    Set-Service w32time -StartupType "Automatic"
}

if ($service.Status -ne "Running") {
    Start-Service "Windows Time"
}

w32tm /resync
