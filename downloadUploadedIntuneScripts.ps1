#=============================================================================================================================
#
# Script Name:      downloadUploadedIntuneScripts.ps1
# Description:      Exports all Intune platform scripts, and a CSV of their details, to the current directory
# Author:           Danny Chrismas - TheAutisticTechie
# Based on:         A script by Nicola Suter (nicolonsky) - https://github.com/nicolonsky
# Source:           https://gist.github.com/theautistictechie/b325e762e3028146cdcad8af81948935
#
#=============================================================================================================================

# The shared Microsoft Intune PowerShell app that Connect-MSGraph used was removed in April 2024, so this uses the
# Microsoft Graph PowerShell SDK instead: Install-Module Microsoft.Graph.Authentication -Scope CurrentUser
# Pass -ClientId and -TenantId to sign in with your own app registration rather than the SDK's default app
param (
    [string]$ClientId,
    [string]$TenantId
)

$connectParams = @{ Scopes = "DeviceManagementScripts.Read.All"; NoWelcome = $true }
if ($ClientId) { $connectParams.ClientId = $ClientId }
if ($TenantId) { $connectParams.TenantId = $TenantId }
Connect-MgGraph @connectParams

# Get device configuration - PowerShell scripts, following any further pages
$scriptIds = @()
$uri = "beta/deviceManagement/deviceManagementScripts"
while ($uri) {
    $request = Invoke-MgGraphRequest -Method GET -Uri $uri
    foreach ($item in $request.value) {
        $scriptIds += $item.id
    }
    $uri = $request.'@odata.nextLink'
}

$allScripts = foreach ($id in $scriptIds) {
    # The list doesn't include the script body, so fetch each script individually
    $currentScript = Invoke-MgGraphRequest -Method GET -Uri "beta/deviceManagement/deviceManagementScripts/$id"
    $bytes = [System.Convert]::FromBase64String($currentScript.scriptContent)

    [PSCustomObject]@{
        id = $currentScript.id
        displayName = $currentScript.displayName
        description = $currentScript.description
        scriptBytes = $bytes
        scriptContent = [System.Text.Encoding]::UTF8.GetString($bytes)
    }
}

# export all scripts as PowerShell files to current directory
# Write the original bytes so each script keeps the encoding it was uploaded with. Out-File would re-save it as UTF-16,
# which Intune rejects if the script is uploaded again
$cwd = Get-Location | Select-Object -ExpandProperty Path
$invalidChars = [Regex]::Escape(-join [System.IO.Path]::GetInvalidFileNameChars())
foreach ($item in $allScripts) {
    $fileName = ($item.displayName -replace "[$invalidChars]", "_") + ".ps1"
    [System.IO.File]::WriteAllBytes((Join-Path -Path $cwd -ChildPath $fileName), $item.scriptBytes)
}

# export all scripts and metadata within a csv file to current directory
$allScripts | Select-Object id, displayName, description, scriptContent |
    Export-Csv -Path (Join-Path -Path $cwd -ChildPath "Intune-PowerShellScripts.csv") -Delimiter ";" -NoTypeInformation
