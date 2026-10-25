# Download SophosSetup.exe from your Sophos Central account (it is already linked to your account, so no customer token
# is needed) and upload it to storage you control, then run this script with -uri set to its URL.
# Intune platform scripts can't pass parameters, so deploy this as a Win32 app with an install command such as:
#   powershell.exe -ExecutionPolicy Bypass -File SophosDeployment.ps1 -uri https://example/SophosSetup.exe

param (
    [string]$uri
)

if (!$uri) {
    Throw "No installer given - run this script with -uri set to the URL of SophosSetup.exe"
}

$InstallerPath = "C:\Temp\Installers"
$File = "SophosSetup.exe"
$Path = $installerPath + "\" + $File

# Check if Sophos is already installed on the computer
# ProgramW6432 is the 64-bit Program Files even when Intune runs this in 32-bit PowerShell
$ProgramFiles = if ($env:ProgramW6432) { $env:ProgramW6432 } else { $env:ProgramFiles }
$InstallCheck = Join-Path $ProgramFiles "Sophos\Sophos UI\Sophos UI.exe"

# Create directory to download the exe file, fail if it can't create it
if (!(Test-Path -PathType Container -Path $installerPath)) {
    Try {
        New-Item $installerPath -ItemType Directory -ErrorAction Stop
    }
    Catch {
        Throw "Failed to create Installer Directory"
    }
}

# Try downloading and installing as long as the Sophos UI.exe isn't in the "Program Files\Sophos" folder
if(!(Test-Path $installCheck)) {
     try {
        $down = New-Object System.Net.WebClient
        $down.DownloadFile($uri,$Path)
        # This runs as SYSTEM, so only run the installer if it has a valid Sophos signature
        $signature = Get-AuthenticodeSignature -FilePath $Path
        if (($signature.Status -ne "Valid") -or ($signature.SignerCertificate.Subject -notlike "*O=Sophos*")) {
            Remove-Item $Path -Force
            Throw "SophosSetup.exe is not validly signed by Sophos - not running it"
        }
        & $path --products=all --quiet
     }
     catch {
         Throw "Failed to install Package: $($_.Exception.Message)"
     }
}
