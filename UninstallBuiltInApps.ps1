# Uninstall Built-in Apps
# Until Intune releases the configuration profile to choose apps to remove

$apps = @(
    "Microsoft.Getstarted"
    "Microsoft.Microsoft3DViewer"
    "Microsoft.MicrosoftSolitaireCollection"
    "Microsoft.NetworkSpeedTest"
    "Microsoft.People"
    "Microsoft.SkypeApp"
    "MicrosoftTeams"
    "Microsoft.WindowsAlarms"
    "Microsoft.windowscommunicationsapps"
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

foreach ($app in $apps){
	try {
		Get-AppxPackage $app -AllUsers | Remove-AppxPackage -AllUsers
        	Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $app | Remove-AppxProvisionedPackage -Online -AllUsers
	} catch {
		write-host "Error uninstalling application"
	}
}
