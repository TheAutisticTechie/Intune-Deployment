Set-ItemProperty -Path Registry::"HKLM\SYSTEM\CurrentControlSet\Services\W32Time\Parameters" -Name "NtpServer" -PropertyType "String" -Value "time.cloudflare.com,0x9" -Force
Set-ItemProperty -Path Registry::"HKLM\SYSTEM\CurrentControlSet\Services\W32Time\Parameters" -Name "Type" -PropertyType "String" -Value "NTP" -Force
