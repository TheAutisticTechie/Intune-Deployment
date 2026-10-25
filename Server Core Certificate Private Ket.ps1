#=============================================================================================================================
#
# Script Name:      Server Core Certificate Private Ket.ps1
# Description:      Gives an IIS application pool read access to a certificate's private key
# Author:           Danny Chrismas - TheAutisticTechie
#
#=============================================================================================================================

$thumbprint = "#" # Thumbprint of the cert
$iisAppPoolName = "#" # Name of the pool under Application Pools

$ErrorActionPreference = "Stop"

$cert = Get-ChildItem Cert:\LocalMachine\My | Where-Object { $_.Thumbprint -eq $thumbprint }
if (!$cert) {
    throw "Certificate $thumbprint not found in LocalMachine\My"
}

# Most current certificates use CNG keys stored under Crypto\Keys; older ones use CSP keys under Crypto\RSA\MachineKeys
$rsa = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($cert)
if ($rsa -is [System.Security.Cryptography.RSACng]) {
    $fullpath = Join-Path $env:ProgramData "Microsoft\Crypto\Keys\$($rsa.Key.UniqueName)"
} elseif ($rsa -is [System.Security.Cryptography.RSACryptoServiceProvider]) {
    $fullpath = Join-Path $env:ProgramData "Microsoft\Crypto\RSA\MachineKeys\$($rsa.CspKeyContainerInfo.UniqueKeyContainerName)"
} else {
    throw "Certificate $thumbprint has no RSA private key on this machine"
}

# Stop rather than change the permissions on the key folder itself
if (!(Test-Path -Path $fullpath -PathType Leaf)) {
    throw "Private key file not found: $fullpath"
}

$Acl = Get-Acl $fullpath
$Ar = New-Object System.Security.AccessControl.FileSystemAccessRule("IIS AppPool\$iisAppPoolName", "Read", "Allow")
$Acl.SetAccessRule($Ar)
Set-Acl $fullpath $Acl
