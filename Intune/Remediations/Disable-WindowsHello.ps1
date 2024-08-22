<#
.SYNOPSIS
    This script disables Windows Hello for Business, which is used for biometric authentication.

.DESCRIPTION
    Windows Hello for Business provides an alternative sign-in method using biometrics or PIN. This script disables the feature for organizations preferring traditional authentication methods.

.EXAMPLE
    .\Disable-WindowsHello.ps1
    This command runs the script and disables Windows Hello for Business.

.NOTES
    Author: Ankit Gupta
    GitHub: https://github.com/ankytgupta

    Always validate and test scripts in a non-production environment before deploying them in your organization.
#>

function Disable-WindowsHello {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path = "HKLM:\SOFTWARE\Policies\Microsoft\PassportForWork",
        
        [Parameter(Mandatory = $true)]
        [string]$Name = "Enabled",
        
        [Parameter(Mandatory = $true)]
        [int]$Value = 0
    )
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -ErrorAction SilentlyContinue
    Write-Output "Windows Hello for Business has been disabled."
}

Disable-WindowsHello
