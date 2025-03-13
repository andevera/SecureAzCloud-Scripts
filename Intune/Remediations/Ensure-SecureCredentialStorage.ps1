<#
.SYNOPSIS
    This script checks and enforces the "DisableDomainCreds" registry setting to prevent local storage of domain credentials.

.DESCRIPTION
    The script verifies if the "DisableDomainCreds" registry value under LSA settings is correctly configured for security compliance.
    If the setting is misconfigured, it attempts to remediate by setting the correct value and verifies the success of remediation.

.PARAMETER None
    No parameters are required.

.EXAMPLE
    .\Enforce-LocalCredentialStoragePolicy.ps1
    Runs the script to check and enforce the registry policy.

.NOTES
    Author: Ankit Gupta
    Version: 1.2 - $(Get-Date -Format "yyyy-MM-dd")
    GitHub Repository: https://github.com/CyberAutomationX/SecureAzCloud-Scripts

    Always test scripts in a non-production environment before deploying them in production.

#>

# Define registry key path
$RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"

# Define registry value name
$RegistryName = "DisableDomainCreds"

# Define the expected value for compliance
$ExpectedValue = 1

# Get current date for logging
$CurrentDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Retrieve the current registry value
$CurrentValue = Get-ItemProperty -Path $RegistryPath -Name $RegistryName -ErrorAction SilentlyContinue | Select-Object -ExpandProperty $RegistryName

# Check compliance
If ($CurrentValue -eq $ExpectedValue) {
    Write-Output "$CurrentDate - Compliant: The registry setting '$RegistryName' is correctly configured."
    Exit 0
} 
Else {
    Write-Warning "$CurrentDate - Not Compliant: The registry setting '$RegistryName' does not match the expected value."
    Write-Host "Attempting remediation..." -ForegroundColor Yellow

    # Remediate by setting the correct registry value
    Try {
        Set-ItemProperty -Path $RegistryPath -Name $RegistryName -Value $ExpectedValue -Force
        # Verify remediation
        $RemediatedValue = Get-ItemProperty -Path $RegistryPath -Name $RegistryName -ErrorAction SilentlyContinue | Select-Object -ExpandProperty $RegistryName
        If ($RemediatedValue -eq $ExpectedValue) {
            Write-Output "$CurrentDate - Fixed: The registry setting '$RegistryName' has been corrected."
            Exit 0
        } 
        Else {
            Write-Warning "$CurrentDate - Remediation failed: Unable to apply the expected registry setting."
            Exit 1
        }
    } 
    Catch {
        Write-Warning "$CurrentDate - Error: Failed to modify the registry. Ensure you have administrator privileges."
        Exit 1
    }
}
