<#
.SYNOPSIS
    This script disables Bluetooth on Windows devices.

.DESCRIPTION
    Bluetooth can pose security risks if not managed properly. This script disables Bluetooth on the system.

.EXAMPLE
    .\Disable-Bluetooth.ps1
    This command runs the script and disables Bluetooth.

.NOTES
    Author: Ankit Gupta
    GitHub: https://github.com/ankytgupta

    Always validate and test scripts in a non-production environment before deploying them in your organization.
#>

function Disable-Bluetooth {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path = "HKLM:\SYSTEM\CurrentControlSet\Services\BTHPORT\Parameters",
        
        [Parameter(Mandatory = $true)]
        [string]$Name = "Enable",
        
        [Parameter(Mandatory = $true)]
        [int]$Value = 0
    )
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -ErrorAction SilentlyContinue
    Write-Output "Bluetooth has been disabled."
}

Disable-Bluetooth
