<#
.SYNOPSIS
    This script disables Windows Automatic Updates.

.DESCRIPTION
    Windows Automatic Updates can be disruptive, especially during work hours. This script disables automatic updates.

.EXAMPLE
    .\Disable-AutomaticUpdates.ps1
    This command runs the script and disables Windows Automatic Updates.

.NOTES
    Author: Ankit Gupta
    GitHub: https://github.com/ankytgupta

    Always validate and test scripts in a non-production environment before deploying them in your organization.
#>

function Disable-AutomaticUpdates {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU",
        
        [Parameter(Mandatory = $true)]
        [string]$Name = "NoAutoUpdate",
        
        [Parameter(Mandatory = $true)]
        [int]$Value = 1
    )
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -ErrorAction SilentlyContinue
    Write-Output "Windows Automatic Updates have been disabled."
}

Disable-AutomaticUpdates
