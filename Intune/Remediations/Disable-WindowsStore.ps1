<#
.SYNOPSIS
    This script disables access to the Windows Store.

.DESCRIPTION
    The Windows Store allows users to download apps. This script disables access to prevent unauthorized app installations.

.EXAMPLE
    .\Disable-WindowsStore.ps1
    This command runs the script and disables access to the Windows Store.

.NOTES
    Author: Ankit Gupta
    GitHub: https://github.com/ankytgupta

    Always validate and test scripts in a non-production environment before deploying them in your organization.
#>

function Disable-WindowsStore {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path = "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore",
        
        [Parameter(Mandatory = $true)]
        [string]$Name = "RemoveWindowsStore",
        
        [Parameter(Mandatory = $true)]
        [int]$Value = 1
    )
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -ErrorAction SilentlyContinue
    Write-Output "Windows Store has been disabled."
}

Disable-WindowsStore
