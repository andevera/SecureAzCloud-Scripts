<#
.SYNOPSIS
    This script disables location tracking in Windows.

.DESCRIPTION
    Windows uses location tracking for various features like weather and search results. This script disables location tracking to protect privacy.

.EXAMPLE
    .\Disable-LocationTracking.ps1
    This command runs the script and disables location tracking.

.NOTES
    Author: Ankit Gupta
    GitHub: https://github.com/ankytgupta

    Always validate and test scripts in a non-production environment before deploying them in your organization.
#>

function Disable-LocationTracking {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors",
        
        [Parameter(Mandatory = $true)]
        [string]$Name = "DisableLocation",
        
        [Parameter(Mandatory = $true)]
        [int]$Value = 1
    )
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -ErrorAction SilentlyContinue
    Write-Output "Location tracking has been disabled."
}

Disable-LocationTracking
