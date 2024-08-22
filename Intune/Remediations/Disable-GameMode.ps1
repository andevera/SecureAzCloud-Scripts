<#
.SYNOPSIS
    This script disables Windows Game Mode.

.DESCRIPTION
    Windows Game Mode optimizes system performance for gaming. This script disables Game Mode to prevent it from impacting other applications.

.EXAMPLE
    .\Disable-GameMode.ps1
    This command runs the script and disables Windows Game Mode.

.NOTES
    Author: Ankit Gupta
    GitHub: https://github.com/ankytgupta

    Always validate and test scripts in a non-production environment before deploying them in your organization.
#>

function Disable-GameMode {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path = "HKCU:\Software\Microsoft\GameBar",
        
        [Parameter(Mandatory = $true)]
        [string]$Name = "AllowAutoGameMode",
        
        [Parameter(Mandatory = $true)]
        [int]$Value = 0
    )
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -ErrorAction SilentlyContinue
    Write-Output "Windows Game Mode has been disabled."
}

Disable-GameMode
