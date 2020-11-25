# https://gist.github.com/dltmurphy/b325e762e3028146cdcad8af81948935

#connects to the default poSH app (Microsoft Intune PowerShell); d1ddf0e4-d672-4dae-b554-9d5bdfd93547
Connect-MSGraph
Update-MSGraphEnvironment -SchemaVersion "Beta"
Connect-MSGraph

# Get device configuration - PowerShell scripts
$request= Invoke-MSGraphRequest -HttpMethod GET -Url "deviceManagement/deviceManagementScripts" -Verbose

$allScripts= @()

$request.value.GetEnumerator() | ForEach-Object {

    #https://graph.microsoft.com/beta/deviceManagement/deviceManagementScripts
    $currentScript =Invoke-MSGraphRequest -HttpMethod GET -Url "deviceManagement/deviceManagementScripts/$($PSItem.id)"
    
    $allScripts += [PSCustomObject]@{
        id = $currentScript.id
        displayName = $currentScript.displayName
        description = $currentScript.description
        scriptContent = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($currentScript.scriptContent))
    }
}

# export all scripts as PowerShell files to current directory

$cwd = Get-Location | select -ExpandProperty Path
$allScripts | ForEach-Object {$PSItem.scriptContent | Out-File -FilePath $(Join-Path -Path $cwd -ChildPath "$($psitem.displayName).ps1")}

# export all scripts and metadata within a csv file  to current directory
$allScripts | Export-Csv -Path $(Join-Path -Path $cwd -ChildPath "Intune-PowerShellScripts.csv") -Delimiter ";" -NoTypeInformation
