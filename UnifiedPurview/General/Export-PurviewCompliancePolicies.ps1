<#
.SYNOPSIS
    Exports all Purview Compliance Policies in your tenant to a CSV file.

.DESCRIPTION
    This script connects to the Microsoft Purview Compliance Center and exports all configured compliance policies, including DLP policies, retention policies, and sensitivity labels, to a CSV file for documentation or review purposes.

.EXAMPLE
    .\Export-PurviewCompliancePolicies.ps1 -OutputPath "C:\CompliancePolicies.csv"

.PARAMETER OutputPath
    The full path to the CSV file where the compliance policies will be exported.

.NOTES
    Author: Ankit Gupta
    GitHub: https://github.com/AnkitG365/SecureAzCloud-Scripts
    Note: You can authenticate using either certificate-based or client secret-based authentication when connecting to IPPSSession.
#>

Param (
    [Parameter(Mandatory = $true)]
    [string]$OutputPath
)

# Connect to Purview Compliance Center
Connect-IPPSSession
# Note: You can authenticate using either certificate-based or client secret-based authentication.

# Get all DLP policies
$dlpPolicies = Get-DlpCompliancePolicy

# Get all retention policies
$retentionPolicies = Get-RetentionPolicy

# Get all sensitivity labels
$sensitivityLabels = Get-Label

# Combine all policies into one object
$allPolicies = $dlpPolicies + $retentionPolicies + $sensitivityLabels

# Export to CSV
$allPolicies | Export-Csv -Path $OutputPath -NoTypeInformation -Force

Write-Host "Compliance policies have been exported to $OutputPath"

# Disconnect the session
Disconnect-IPPSSession
