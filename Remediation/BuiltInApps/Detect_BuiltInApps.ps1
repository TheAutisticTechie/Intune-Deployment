#=============================================================================================================================
#
# Script Name:    Detect_BuiltInApps.ps1
# Description:    Detects if specific built-in apps are installed
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
    foreach ($app in $apps) {
        if(Get-AppxPackage $app -AllUsers){
            exit 1
        }

        if(Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $app){
            exit 1 # Exit whenever one app is found
        }
    }
}
catch {
    $errMsg = $_.Exception.Message
    Write-Error $errMsg
    exit 1
}