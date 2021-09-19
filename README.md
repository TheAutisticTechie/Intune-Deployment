# Intune-Deployment

PRs are welcome

## Sophos Deployment

Checks if Sophos Endpoint is currently installed before installing it using the parameters given. If you use it, ensure you change the customertoken and mgmtserver in the & $path --% line

## Time Config

Sets time.cloudflare.com as the NTP server

## Trend Uninstall

Force uninstalls Trend Micro

## Download Uploaded Intune Scripts

Connect to Microsoft Graph and download all your uploaded scripts to Intune. Forked from nicolonsky

## Windows Updates Reset

Reset Windows Server Update Services so that devices can update automatically from Windows Update. Needed as our WSUS connected devices cannot update whilst working from home, and Intune policies are overridden by the WSUS setting

## Add Firewall Rules

Adds firewall rules to the logged in user. Forked from mardahl
