<#
.SYNOPSIS
    This script disables Windows Spotlight.

.DESCRIPTION
    Windows Spotlight displays images on the lock screen and Start menu. This script disables Windows Spotlight.

.EXAMPLE
    .\Disable-WindowsSpotlight.ps1
    This command runs the script and disables Windows Spotlight.

.NOTES
    Author: Ankit Gupta
    GitHub: https://github.com/ankytgupta

    Always validate and test scripts in a non-production environment before deploying them in your organization.
#>

function Disable-WindowsSpotlight {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent",
        
        [Parameter(Mandatory = $true)]
        [string]$Name = "DisableWindowsSpotlight",
        
        [Parameter(Mandatory = $true)]
        [int]$Value = 1
    )
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -ErrorAction SilentlyContinue
