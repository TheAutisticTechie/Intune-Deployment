# Intune-Deployment

PRs are welcome

## Sophos Deployment

Checks if Sophos Endpoint is currently installed before installing it using the parameters given. If you use it, ensure you change the customertoken and mgmtserver in the & $path --% line

## Time Config

Sets time.cloudflare.com as the NTP server

## Trend Uninstall (archived)

Force uninstalls Trend Micro Worry-Free Business Security Agent using Trend's uninstall tool (TrendUninstall.ps1, TrendMicroUninstall.bat and the TrendMicroUninstall folder). Archived and kept for reference only

## Download Uploaded Intune Scripts

Connect to Microsoft Graph and download all your uploaded scripts to Intune. Forked from nicolonsky

## Windows Updates Reset

Reset Windows Server Update Services so that devices can update automatically from Windows Update. Needed as our WSUS connected devices cannot update whilst working from home, and Intune policies are overridden by the WSUS setting

## Add Firewall Rules (archived)

Adds firewall rules to the logged in user for classic Teams. Forked from mardahl. Archived as classic Teams reached end of availability on 1 July 2025, and the script does not apply to new Teams
