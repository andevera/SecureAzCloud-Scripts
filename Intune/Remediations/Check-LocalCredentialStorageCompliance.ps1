<#
.SYNOPSIS
    This script checks if the "DisableDomainCreds" registry setting is correctly configured for security compliance.

.DESCRIPTION
    The script verifies the "DisableDomainCreds" registry key under the LSA settings in Windows to ensure 
    that domain credentials are not stored locally. If the setting matches the expected value, it outputs "Compliant."
    Otherwise, it outputs "Not Compliant" and exits with a non-zero status.

.PARAMETER None
    This script does not require any parameters.

.EXAMPLE
    .\Check-DisableDomainCreds.ps1
    This example runs the script and checks if the registry setting is compliant.

.NOTES
    Author: Ankit Gupta
    Version: 1.1 - $(Get-Date -Format "yyyy-MM-dd")
    GitHub Repository: https://github.com/CyberAutomationX/SecureAzCloud-Scripts

    Always test scripts in a non-production environment before deploying them in production.
#>

# Define registry key path
$RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"

# Define registry value name
$RegistryName = "DisableDomainCreds"

# Define the expected value for compliance
$ExpectedValue = "1"

# Retrieve the current registry value
$CurrentValue = Get-ItemProperty -Path $RegistryPath -Name $RegistryName -ErrorAction SilentlyContinue | Select-Object -ExpandProperty $RegistryName

# Get current date for logging
$CurrentDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Check compliance and output result
If ($CurrentValue -eq $ExpectedValue) {
    Write-Output "$CurrentDate - Compliant: The registry setting '$RegistryName' is correctly configured."
    Exit 0
} 
Else {
    Write-Warning "$CurrentDate - Not Compliant: The registry setting '$RegistryName' does not match the expected value."
    Exit 1
}
