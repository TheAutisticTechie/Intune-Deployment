function Get-Up {
    $boot = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
    $uptime = (Get-Date) - $boot
    $display = "Uptime: " + $uptime.Days + " days"
    Write-Output $display
}

Get-Up
