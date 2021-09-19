$thumb = Read-Host "Enter the certificate thumbprint"
$cert = Get-ChildItem Cert:\LocalMachine\WebHosting |Where-Object {$_.Thumbprint -eq $thumb}

$siteAHttpHost = @(
    #"example.com",
    #"www.example.com"
)

$siteAHttpsHost = @(
    #"example.com",
    #"www.example.com"
)

$siteA = Read-Host "Enter the Site Name"

foreach ($hostname in $siteAHttpHost){
    New-WebBinding -Name $siteA -IPAddress "*" -port 80 -HostHeader $hostname
}

foreach ($hostname in $siteAHttpsHost){
    Remove-WebBinding -Name $siteA -IPAddress "*" -port 443 -HostHeader $hostname
    New-WebBinding -Name $siteA -IPAddress "*" -port 443 -HostHeader $hostname -Protocol "https" -SslFlags 1
    Remove-Item -Path "IIS:\SslBindings\!443!$hostname"
    New-Item -Path "IIS:\SslBindings\!443!$hostname" -Value $cert -SSLFlags 1
}

#Expand as necessary
