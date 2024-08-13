<#
.SYNOPSIS
    This script tracks and reports changes made to sensitivity labels, sensitivity label policies,
    and retention labels within Microsoft 365 by analyzing audit records.

.DESCRIPTION
    The Audit-LabelPolicyChanges script is designed to retrieve and process audit records 
    related to modifications in sensitivity labels, sensitivity label policies, and retention labels. 
    It connects to Microsoft 365 services to gather relevant data and then generates a detailed report 
    of the actions taken, including who made the changes and when.

.PARAMETER None
    No parameters are required for this script.

.EXAMPLE
    .\Audit-LabelPolicyChanges.PS1
    This example runs the script to retrieve audit logs related to label changes 
    and generates a report that is displayed in an Out-GridView window.

.NOTES
    Author: Ankit Gupta
    Version: 1.1 - 25-Aug-2024
    GitHub Link: https://github.com/SecureAzCloud/Office365Scripts/blob/master/Audit-LabelPolicyChanges.PS1

    This script should be tested in a non-production environment before being used in production.

#>

# Check for existing connections and establish connections as necessary
$LoadedModules = Get-Module | Select-Object -ExpandProperty Name
If ("ExchangeOnlineManagement" -notin $LoadedModules) {
    Write-Host "Initializing connection to Exchange Online..."
    Connect-ExchangeOnline -SkipLoadingCmdletHelp
    Connect-IPPSSession
}

# Connect to Microsoft Graph to retrieve service principal details
Connect-MgGraph -Scopes Application.Read.All

# Retrieve all sensitivity labels and build a lookup table for label names
$SensitivityLabels = Get-Label
$LabelLookup = @{}
ForEach ($Label in $SensitivityLabels) {
    $LabelLookup.Add($Label.ImmutableId, $Label.Name)
}

Write-Host "Gathering audit records for label changes..."
# Identify operations related to sensitivity and retention labels
[array]$AuditOperations = "Set-RetentionCompliancePolicy", "Set-Label", "Set-LabelPolicy", `
    "Set-RetentionComplianceRule", "UpdateLabelPolicy"
[array]$AuditLogs = Search-UnifiedAuditLog -StartDate (Get-Date).AddDays(-60) -EndDate (Get-Date).AddDays(1) -ResultSize 1200 -Formatted -Operations $AuditOperations -SessionCommand ReturnLargeSet
If (!$AuditLogs) { 
    Write-Host "No relevant audit records were found."; break 
} Else {
    $AuditLogs = $AuditLogs | Sort-Object Identity -Unique | Sort-Object {$_.CreationDate -as [datetime]} -Descending
    Write-Host ("Located {0} audit records" -f $AuditLogs.Count)
}

$AuditReport = [System.Collections.Generic.List[Object]]::new()
Write-Host "Processing audit records..."
ForEach ($Record in $AuditLogs) {
    $ParsedData = $null
    $CurrentLabelName = $null
    $ParsedAuditData = $Record.AuditData | ConvertFrom-Json

    Switch ($Record.Operations) {
        "Set-RetentionCompliancePolicy" { # Retention policy modification
            $ParsedData = $ParsedAuditData.Parameters
        }
        "Set-RetentionComplianceRule" { # Retention rule modification
            $ParsedData = $ParsedAuditData.Parameters
        }
        "Set-Label" { # Sensitivity label modification
            $ParsedData = $ParsedAuditData.Parameters
            $CurrentLabelName = $LabelLookup[$ParsedAuditData.ObjectId]
            If (-not $CurrentLabelName) {
                $CurrentLabelName = "Label not found in the tenant"
            }
        }
        "Set-LabelPolicy" { # Sensitivity label policy modification
            $ParsedData = $ParsedAuditData.Parameters
        }   
        "UpdateLabelPolicy" { # Retention label modification
            $CurrentLabelName = $ParsedAuditData.target.id[3]
            $ParsedData = $ParsedAuditData.ObjectId
        }
    }

    If ($Record.UserIds -like "*ServicePrincipal*") {
        $SPStartIndex = $Record.UserIds.IndexOf("_") + 1
        $ServicePrincipalId = $Record.UserIds.SubString($SPStartIndex, $Record.UserIds.Length - $SPStartIndex)

        $UserDisplayName = (Get-MgServicePrincipal -ServicePrincipalId $ServicePrincipalId).displayName
    } Else {
        $UserDisplayName = $Record.UserIds
    }

    $ReportEntry = [PSCustomObject] @{ 
        User          = $UserDisplayName
        Operation     = $Record.Operations
        Timestamp     = (Get-Date $Record.CreationDate -Format 'dd-MMM-yyyy HH:mm:ss')
        Details       = $ParsedData
        LabelName     = $CurrentLabelName    
    }
    $AuditReport.Add($ReportEntry)
}

$AuditReport | Out-Gridview -Title 'Audit Records for Label and Policy Changes'

# Example script for illustrating concepts in Microsoft 365 security auditing. More information and best practices can be found on the SecureAzCloud website.
# Always validate and test scripts in a non-production environment before deploying them in your organization.
