# Download the blank thin installer and upload to publicly accessible website or storage
$url = "http://delltechcentre.com/TrendMicroUninstall.zip"
$installerPath = "C:\TrendUninstallTemp"
$file = "TrendMicroUninstall.zip"
$uninstallFile = "Uninstall.bat"
$path = $installerPath + "\" + $File
$scriptUninstallPath = "$installerPath" + "\" + "$uninstallFile"

# Check if Trend micro is already installed on the computer
$installCheck = Join-Path ([System.Environment]::GetFolderPath("ProgramFilesx86")) "Trend Micro\Security Agent\PccNTMon.exe"

# Try downloading and running as long as the PccNTMon.exe isn't in the "Program Files" folder
if(Test-Path $installCheck) {
     try {
        # Create directory to download the zip file, fail if it can't create it
        if (!(Test-Path -PathType Container -Path $installerPath)) {
            Try {
                New-Item $installerPath -ItemType Directory -ErrorAction Stop
            }
            Catch {
                Throw "Failed to create Temp Directory"
            }
        }
        $down = New-Object System.Net.WebClient
        $down.DownloadFile($url,$path)
        #Extract the zip contents
        $shell = new-object -com shell.application
        $zip = $shell.NameSpace("C:\TrendUninstallTemp\TrendMicroUninstall.zip")
        foreach($item in $zip.items()){
            $shell.Namespace("C:\TrendUninstallTemp\").copyhere($item)
        }
        & $scriptUninstallPath
     }
     catch {
         Throw "Failed to run script"
     }
}
