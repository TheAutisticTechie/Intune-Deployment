# Download the blank thin installer and upload to publicly accessible website or storage - for testing I put it on my own temporarily
# Replace the **** with your customer details

$URL = "https://dltmurphy.co.uk/SophosSetup.exe"
$InstallerPath = "C:\Temp\Installers"
$File = "SophosSetup.exe"
$Path = $installerPath + "\" + $File

$InstallCheck = Join-Path ([System.Environment]::GetFolderPath("ProgramFiles")) "Sophos\Sophos UI.exe"
if (!(Test-Path -PathType Container -Path $installerPath)) {
    Try {
        New-Item $installerPath -ItemType Directory -ErrorAction Stop
    }
    Catch {
        Throw "Failed to create Installer Directory"
    }
}
 
if(!(Test-Path $installCheck)) {
     try {
        $down = New-Object System.Net.WebClient
        $down.DownloadFile($URL,$Path)
        & $path --% --customertoken="****" --mgmtserver="****" --products="all" --quiet
     }
     catch {
         Throw "Failed to install Package"
     }       
}
