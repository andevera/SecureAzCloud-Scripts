<#
.SYNOPSIS
    This script audits user sign-ins, tracks MFA usage details, and generates a detailed report on user activities within Entra ID using Microsoft Graph.

.DESCRIPTION
    The Audit-MFAUserSignIns script connects to Microsoft Graph API to retrieve user sign-in activities, including details about MFA usage.
    It generates a report with various fields, including user information, sign-in date, MFA method used, and success or failure of sign-in.
    This report helps organizations track MFA usage, compliance, and analyze user behavior over a period of time.

.PARAMETER StartDate
    Defines the start date for the audit period.

.PARAMETER EndDate
    Defines the end date for the audit period.

.PARAMETER ExportPath
    Specifies the path to export the CSV file for the report.

.EXAMPLE
    .\Audit-MFAUserSignIns.ps1 -StartDate '2024-08-01' -EndDate '2024-08-30' -ExportPath 'C:\Reports\MFA_AuditReport.csv'

.NOTES
    Author: Ankit Gupta
    Version: 1.0 - 30-Sept-2024
    GitHub Repository: https://github.com/AnkitG365/SecureAzCloud-Scripts
    Always test scripts in a non-production environment before running them in production.
#>

param (
    [Parameter(Mandatory = $true, HelpMessage = "Specify the start date for the report")]
    [datetime]$StartDate,

    [Parameter(Mandatory = $true, HelpMessage = "Specify the end date for the report")]
    [datetime]$EndDate,

    [Parameter(Mandatory = $true, HelpMessage = "Specify the export path for the CSV report")]
    [string]$ExportPath
)

# Connect to Microsoft Graph API (either via Certificate or Client Secret-based Authentication)
# You can either use certificate or client secret-based authentication, but here we use interactive login for simplicity.

Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Green
Connect-MgGraph -Scopes "AuditLog.Read.All", "Directory.Read.All" 

$TenantID = (Get-MgOrganization).Id
$StartDateISO = $StartDate.ToString("yyyy-MM-ddTHH:mm:ssZ")
$EndDateISO = $EndDate.ToString("yyyy-MM-ddTHH:mm:ssZ")

# Function to retrieve sign-in logs
function Get-SignInLogs {
    param (
        [string]$StartDateISO,
        [string]$EndDateISO
    )

    Write-Host "Retrieving sign-in logs from $StartDate to $EndDate..." -ForegroundColor Yellow

    # Query sign-in logs with filters
    $SignInLogs = Get-MgAuditLogSignIn `
        -Filter "createdDateTime ge $StartDateISO and createdDateTime le $EndDateISO" `
        -All `
        -Property "userPrincipalName, createdDateTime, status, mfaDetail"

    return $SignInLogs
}

# Retrieve sign-in logs within the specified date range
$SignInData = Get-SignInLogs -StartDateISO $StartDateISO -EndDateISO $EndDateISO

if (-not $SignInData) {
    Write-Warning "No sign-in data found for the specified period!"
    return
}

# Process and build the report data
$Report = @()
foreach ($log in $SignInData) {
    $MFAStatus = "N/A"
    $MFAMethod = "None"

    if ($log.MfaDetail -ne $null) {
        $MFAStatus = "MFA Performed"
        $MFAMethod = ($log.MfaDetail.AuthenticationMethodDetails | ForEach-Object { $_.MethodType }) -join ", "
    } else {
        $MFAStatus = "Single-Factor Authentication"
    }

    $Report += [pscustomobject]@{
        UserPrincipalName = $log.UserPrincipalName
        SignInDateTime    = $log.CreatedDateTime
        Status            = $log.Status.ErrorCode -eq 0 ? "Success" : "Failure"
        MFAStatus         = $MFAStatus
        MFAMethod         = $MFAMethod
        ClientAppUsed     = $log.ClientAppUsed
        IPAddress         = $log.IPAddress
    }
}

# Export the report to CSV
$Report | Export-Csv -Path $ExportPath -NoTypeInformation -Force
Write-Host "MFA Audit Report successfully exported to $ExportPath" -ForegroundColor Green

# Disconnect from Microsoft Graph
Disconnect-MgGraph

Write-Host "Audit Completed." -ForegroundColor Green
