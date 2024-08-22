<#
.SYNOPSIS
    This script disables background apps in Windows.

.DESCRIPTION
    Background apps run in the background and consume resources. This script disables background apps to improve performance.

.EXAMPLE
    .\Disable-BackgroundApps.ps1
    This command runs the script and disables background apps.

.NOTES
    Author: Ankit Gupta
    GitHub: https://github.com/ankytgupta

    Always validate and test scripts in a non-production environment before deploying them in your organization.
#>

function Disable-BackgroundApps {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy",
        
        [Parameter(Mandatory = $true)]
        [string]$Name = "LetAppsRunInBackground",
        
        [Parameter(Mandatory = $true)]
        [int]$Value = 2
    )
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -ErrorAction SilentlyContinue
    Write-Output "Background apps have been disabled."
}

Disable-BackgroundApps
