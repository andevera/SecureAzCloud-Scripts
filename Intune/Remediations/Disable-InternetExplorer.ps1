<#
.SYNOPSIS
    This script disables Internet Explorer.

.DESCRIPTION
    Internet Explorer is an outdated web browser. This script disables Internet Explorer to encourage the use of modern browsers.

.EXAMPLE
    .\Disable-InternetExplorer.ps1
    This command runs the script and disables Internet Explorer.

.NOTES
    Author: Ankit Gupta
    GitHub: https://github.com/ankytgupta

    Always validate and test scripts in a non-production environment before deploying them in your organization.
#>

function Disable-InternetExplorer {
    Disable-WindowsOptionalFeature -FeatureName Internet-Explorer-Optional-amd64 -Online -NoRestart
    Write-Output "Internet Explorer has been disabled."
}

Disable-InternetExplorer
