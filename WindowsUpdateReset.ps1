$reg = "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate"

if (Test-Path $reg) {
	Stop-Service -Name wuauserv
	Remove-Item $reg -Recurse
	Start-Service -Name wuauserv
}
