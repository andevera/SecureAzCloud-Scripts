<#
.SYNOPSIS
    This script disables the lock screen background image.

.DESCRIPTION
    The Windows lock screen displays a background image by default. This script disables the background image to improve privacy.

.EXAMPLE
    .\Disable-LockScreenImage.ps1
    This command runs the script and disables the lock screen background image.

.NOTES
    Author: Ankit Gupta
    GitHub: https://github.com/ankytgupta

    Always validate and test scripts in a non-production environment before deploying them in your organization.
#>

function Disable-LockScreenImage {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization",
        
        [Parameter(Mandatory = $true)]
        [string]$Name = "NoLockScreen",
        
        [Parameter(Mandatory = $true)]
        [int]$Value = 1
    )
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -ErrorAction SilentlyContinue
    Write-Output "Lock screen background image has been disabled."
}

Disable-LockScreenImage
