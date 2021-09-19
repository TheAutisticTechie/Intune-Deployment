# Uninstall Built-in Apps
# Until Intune releases the configuration profile to choose apps to remove

$apps = @(
    "Microsoft.GetHelp"
    "Microsoft.Getstarted"
    "Microsoft.Microsoft3DViewer"
    "Microsoft.MicrosoftSolitaireCollection"
    "Microsoft.NetworkSpeedTest"
    "Microsoft.People"
    "Microsoft.Print3D"
    "Microsoft.SkypeApp"
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
		Get-AppxPackage $app | Remove-AppxPackage
        Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $app | Remove-AppxProvisionedPackage -Online
	} catch {
		write-host "Error uninstalling application"
	}
}
