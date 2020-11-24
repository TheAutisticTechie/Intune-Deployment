Set-ItemProperty -Path Registry::"HKLM\SYSTEM\CurrentControlSet\Services\W32Time\Parameters" -Name "NtpServer" -Type "String" -Value "time.cloudflare.com,0x9" -Force
Set-ItemProperty -Path Registry::"HKLM\SYSTEM\CurrentControlSet\Services\W32Time\Parameters" -Name "Type" -Type "String" -Value "NTP" -Force
