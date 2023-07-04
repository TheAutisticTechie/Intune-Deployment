#=============================================================================================================================
#
# Script Name:    Remediate_BuiltInApps.ps1
# Description:    Uninstall specific built-in apps
#
#=============================================================================================================================

$apps = @(
    "DellInc.DellSupportAssistforPCs"
    "Microsoft.Microsoft3DViewer"
    "Microsoft.MicrosoftSolitaireCollection"
    "Microsoft.NetworkSpeedTest"
    "Microsoft.People"
    "Microsoft.SkypeApp"
    "MicrosoftTeams"
    "Microsoft.WindowsAlarms"
    "Microsoft.windowscommunicationsapps"
    "Microsoft.WindowsMaps"
    "Microsoft.XboxApp"
    "Microsoft.XboxGameOverlay"
    "Microsoft.XboxGamingOverlay"
    "Microsoft.XboxIdentityProvider"
    "Microsoft.XboxSpeechToTextOverlay"
    # Sponsored
    "*Duolingo-LearnLanguagesforFree*"
    "*PandoraMediaInc*"
    "*CandyCrush*"
    "*BubbleWitch3Saga*"
    "*Wunderlist*"
    "*Flipboard*"
    "*Minecraft*"
    "*Royal Revolt*"
    "*Speed Test*"
    "*Dolby*"
)

try {
    foreach ($app in $apps){
	    try {
		    Get-AppxPackage $app -AllUsers | Remove-AppxPackage -AllUsers
            Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $app | Remove-AppxProvisionedPackage -Online -AllUsers
	    } catch {
		    write-host "Error uninstalling application"
            exit 1
	    }
    }
    exit 0
}
catch {
    $errMsg = $_.Exception.Message
    Write-Error $errMsg
    exit 1
}