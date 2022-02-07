$thumbprint = "#" # Thumbprint of the cert
$iisAppPoolName = "#" # Name of the pool under Application Pools

$keyname = (((gci cert:\LocalMachine\my | ? {$_.thumbprint -like $thumbprint}).PrivateKey).CspKeyContainerInfo).UniqueKeyContainerName
$keypath = $env:ProgramData + “\Microsoft\Crypto\RSA\MachineKeys\”
$fullpath = $keypath + $keyname

$Acl = Get-Acl $fullpath
$Ar = New-Object System.Security.AccessControl.FileSystemAccessRule("IIS AppPool\$iisAppPoolName", "Read", "Allow")
$Acl.SetAccessRule($Ar)
Set-Acl $fullpath $Acl