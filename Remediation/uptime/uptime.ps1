function Get-Up {
    $dtformat = "\[DD/mm/yyyy HH:mm:ss tt\]"
    $boot = Get-WmiObject win32_operatingsystem @{LABEL='LastBootUpTime';EXPRESSION={$_.ConverttoDateTime($_.lastbootuptime)}}
    $uptime = (Get-Date)-($boot.LastBootUpTime -f $dtformat)
    $display = "Uptime: " + $Uptime.Days + " days" 
    Write-Output $display
}

Get-Up