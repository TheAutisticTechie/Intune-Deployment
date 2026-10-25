# Intune-Deployment

PRs are welcome

## Licence

MIT, see [LICENSE](LICENSE). Code from other authors keeps its original notices: AddFirewallRule.ps1 (Microsoft and Michael Mardahl) and downloadUploadedIntuneScripts.ps1 (Nicola Suter). The TrendMicroUninstall folder and TrendMicroUninstall.bat are Trend Micro's own tool and aren't covered by this licence

## Sophos Deployment

Checks if Sophos Endpoint is currently installed before downloading and installing it. Download SophosSetup.exe from your Sophos Central account, host it somewhere the devices can reach, and run the script with -uri set to its URL (for example as a Win32 app install command, as Intune platform scripts can't pass parameters)

## Time Config

Remediation (Remediation/TimeConfig) that sets time.cloudflare.com as the NTP server and keeps the Windows Time service running on laptops that aren't joined to an AD domain. Run it as SYSTEM on a daily schedule

## Trend Uninstall (archived)

Force uninstalls Trend Micro Worry-Free Business Security Agent using Trend's uninstall tool (TrendUninstall.ps1, TrendMicroUninstall.bat and the TrendMicroUninstall folder). Archived and kept for reference only

## Download Uploaded Intune Scripts

Connect to Microsoft Graph and download all your uploaded scripts to Intune. Forked from nicolonsky

## Windows Updates Reset

Reset Windows Server Update Services so that devices can update automatically from Windows Update. Needed as our WSUS connected devices cannot update whilst working from home, and Intune policies are overridden by the WSUS setting

## Add Firewall Rules (archived)

Adds firewall rules to the logged in user for classic Teams. Forked from mardahl. Archived as classic Teams reached end of availability on 1 July 2025, and the script does not apply to new Teams
