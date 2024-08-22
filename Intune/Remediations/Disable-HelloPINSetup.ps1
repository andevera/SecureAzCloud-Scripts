<#
.SYNOPSIS
    This script disables Windows Hello PIN setup.

.DESCRIPTION
    Windows Hello offers users a secure way to sign in using a PIN. This script disables the PIN setup option.

.EXAMPLE
    .\Disable-HelloPINSetup.ps1
    This command runs the script and disables Windows Hello PIN setup.

.NOTES
    Author: Ankit Gupta
    GitHub: https://github.com/ankytgupta

    Always validate and test scripts in a non-production environment before deploying them in your organization.
#>

function Disable-HelloPINSetup {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path = "HKLM:\SOFTWARE\Policies\Microsoft\PassportForWork",
        
        [Parameter(Mandatory = $true)]
        [string]$Name = "Enabled",
        
        [Parameter(Mandatory = $true)]
        [int]$Value = 0
    )
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -ErrorAction SilentlyContinue
    Write-Output "Windows Hello PIN setup has been disabled."
}

Disable-HelloPINSetup
