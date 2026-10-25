#=============================================================================================================================
#
# Script Name:      Remediate_Uptime.ps1
# Description:      Asks the user to restart, and schedules a forced restart if they don't
#                   Run using the logged-on credentials, as a notification from SYSTEM isn't visible to the user
# Author:           Danny Chrismas - TheAutisticTechie
#
#=============================================================================================================================

# Variables
$restartDelayHours = 24
$markerKey = "HKCU:\Software\Intune-Deployment\Uptime"

function Show-Notification($title, $text) {
    # Windows notification types, available in Windows PowerShell 5.1
    $null = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
    $null = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]

    $title = [System.Security.SecurityElement]::Escape($title)
    $text = [System.Security.SecurityElement]::Escape($text)

    # The reminder scenario keeps the notification on screen until the user dismisses it
    $xml = New-Object Windows.Data.Xml.Dom.XmlDocument
    $xml.LoadXml(@"
<toast scenario="reminder">
    <visual>
        <binding template="ToastGeneric">
            <text>$title</text>
            <text>$text</text>
        </binding>
    </visual>
    <actions>
        <action activationType="system" arguments="dismiss" content=""/>
    </actions>
</toast>
"@)

    # Show it as coming from Windows PowerShell, which is registered for notifications on every device
    $appId = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'
    $toast = New-Object Windows.UI.Notifications.ToastNotification $xml
    [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId).Show($toast)
}

try {
    $uptimeDays = ((Get-Date) - (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime).Days
    $restartAt = (Get-Date).AddHours($restartDelayHours)
    $message = "Your device hasn't restarted in $uptimeDays days. Please save your work and restart when you can, otherwise it will restart automatically on $($restartAt.ToString("dddd 'at' HH:mm"))."

    # Restarting before then cancels this. Exit code 1190 means a restart is already scheduled
    shutdown.exe /r /t ($restartDelayHours * 3600) /c $message
    if ($LASTEXITCODE -notin 0, 1190) {
        throw "shutdown.exe failed with exit code $LASTEXITCODE"
    }

    # Lets Detect_Uptime.ps1 report the device as handled until the restart is due
    New-Item -Path $markerKey -Force | Out-Null
    Set-ItemProperty -Path $markerKey -Name "ScheduledAt" -Value (Get-Date).ToString("o")
    Set-ItemProperty -Path $markerKey -Name "RestartAt" -Value $restartAt.ToString("o")

    try {
        Show-Notification "Restart needed" $message
    }
    catch {
        Write-Host "Couldn't show the notification: $($_.Exception.Message)"
    }

    Write-Host "Restart scheduled for $restartAt"
    exit 0
}
catch {
    $errMsg = $_.Exception.Message
    Write-Error $errMsg
    exit 1
}
