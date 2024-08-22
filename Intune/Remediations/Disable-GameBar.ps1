<#
.SYNOPSIS
    This script disables the Windows Game Bar.

.DESCRIPTION
    The Windows Game Bar provides gaming tools and recording features. This script disables the Game Bar to prevent performance impact.

.EXAMPLE
    .\Disable-GameBar.ps1
    This command runs the script and disables the Windows Game Bar.

.NOTES
    Author: Ankit Gupta
    GitHub: https://github.com/ankytgupta

    Always validate and test scripts in a non-production environment before deploying them in your organization.
#>

function Disable-GameBar {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path = "HKCU:\Software\Microsoft\GameBar",
        
        [Parameter(Mandatory = $true)]
        [string]$Name = "ShowStartupPanel",
        
        [Parameter(Mandatory = $true)]
        [int]$Value = 0
    )
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -ErrorAction SilentlyContinue
    Write-Output "Windows Game Bar has been disabled."
}

Disable-GameBar
