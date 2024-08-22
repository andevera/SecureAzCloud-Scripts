<#
.SYNOPSIS
    This script disables SMBv1 on Windows devices.

.DESCRIPTION
    SMBv1 is an older version of the Server Message Block protocol that is vulnerable to attacks. This script disables SMBv1 to enhance security.

.EXAMPLE
    .\Disable-SMBv1.ps1
    This command runs the script and disables SMBv1.

.NOTES
    Author: Ankit Gupta
    GitHub: https://github.com/ankytgupta

    Always validate and test scripts in a non-production environment before deploying them in your organization.
#>

function Disable-SMBv1 {
    Disable-WindowsOptionalFeature -Online -FeatureName "SMB1Protocol" -NoRestart -ErrorAction SilentlyContinue
    Write-Output "SMBv1 has been disabled."
}

Disable-SMBv1
