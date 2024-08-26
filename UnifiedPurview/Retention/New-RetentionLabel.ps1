<#
.SYNOPSIS
    Creates a new Retention Label in Microsoft Purview with specified retention settings.

.DESCRIPTION
    This script creates a new retention label in Purview with a specific retention duration and action upon retention expiry.

.EXAMPLE
    .\New-RetentionLabel.ps1 -LabelName "Confidential" -RetentionDuration 365 -RetentionAction "Delete"

.PARAMETER LabelName
    The name of the new retention label.

.PARAMETER RetentionDuration
    The duration (in days) for which content should be retained.

.PARAMETER RetentionAction
    The action to be taken when the retention period expires (e.g., "Delete" or "DoNothing").

.NOTES
    Author: Ankit Gupta
    GitHub: https://github.com/AnkitG365/SecureAzCloud-Scripts
    Note: You can authenticate using either certificate-based or client secret-based authentication when connecting to IPPSSession.
#>

Param (
    [Parameter(Mandatory = $true)]
    [string]$LabelName,
    
    [Parameter(Mandatory = $true)]
    [int]$RetentionDuration,
    
    [Parameter(Mandatory = $true)]
    [ValidateSet("Delete", "DoNothing")]
    [string]$RetentionAction
)

# Connect to Purview Compliance Center
Connect-IPPSSession
# Note: You can authenticate using either certificate-based or client secret-based authentication.

# Create the new retention label
New-RetentionCompliancePolicy -Name $LabelName -RetentionDuration $RetentionDuration -RetentionAction $RetentionAction

Write-Host "Retention label '$LabelName' created with a retention period of $RetentionDuration days and action '$RetentionAction'."

# Disconnect the session
Disconnect-IPPSSession
