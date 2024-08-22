<#
.SYNOPSIS
    This script disables OneDrive integration in Windows.

.DESCRIPTION
    OneDrive is integrated into Windows for file synchronization. This script disables the integration to prevent data synchronization to OneDrive.

.EXAMPLE
    .\Disable-OneDrive.ps1
    This command runs the script and disables OneDrive integration.

.NOTES
    Author: Ankit Gupta
    GitHub: https://github.com/ankytgupta

    Always validate and test scripts in a non-production environment before deploying them in your organization.
#>

function Disable-OneDrive {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive",
        
        [Parameter(Mandatory = $true)]
        [string]$Name = "DisableFileSyncNGSC",
        
        [Parameter(Mandatory = $true)]
        [int]$Value = 1
    )
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -ErrorAction SilentlyContinue
    Write-Output "OneDrive integration has been disabled."
}

Disable-OneDrive
