<#
.SYNOPSIS
    This script disables Cortana via the registry.

.DESCRIPTION
    Cortana is a virtual assistant by Microsoft. This script disables Cortana for users who do not need this feature.

.EXAMPLE
    .\Disable-Cortana.ps1
    This command runs the script and disables Cortana.

.NOTES
    Author: Ankit Gupta
    GitHub: https://github.com/ankytgupta

    Always validate and test scripts in a non-production environment before deploying them in your organization.
#>

function Disable-Cortana {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search",
        
        [Parameter(Mandatory = $true)]
        [string]$Name = "AllowCortana",
        
        [Parameter(Mandatory = $true)]
        [int]$Value = 0
    )
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -ErrorAction SilentlyContinue
    Write-Output "Cortana has been disabled."
}

Disable-Cortana
