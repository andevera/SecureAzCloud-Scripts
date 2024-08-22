<#
.SYNOPSIS
    This script disables Windows Update Delivery Optimization.

.DESCRIPTION
    Delivery Optimization allows Windows to download updates from other computers on the internet. This script disables Delivery Optimization to prevent bandwidth usage.

.EXAMPLE
    .\Disable-DeliveryOptimization.ps1
    This command runs the script and disables Delivery Optimization.

.NOTES
    Author: Ankit Gupta
    GitHub: https://github.com/ankytgupta

    Always validate and test scripts in a non-production environment before deploying them in your organization.
#>

function Disable-DeliveryOptimization {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization",
        
        [Parameter(Mandatory = $true)]
        [string]$Name = "DODownloadMode",
        
        [Parameter(Mandatory = $true)]
        [int]$Value = 0
    )
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -ErrorAction SilentlyContinue
    Write-Output "Windows Update Delivery Optimization has been disabled."
}

Disable-DeliveryOptimization
