<#
.SYNOPSIS
    Retrieves the audit logs from Entra ID.

.DESCRIPTION
    This script retrieves the audit logs from Entra ID.

.EXAMPLE
    .\Get-AuditLogs.ps1 -StartDate "2024-08-01T00:00:00Z" -EndDate "2024-08-07T23:59:59Z"

.PARAMETER StartDate
    The start date for the audit logs.

.PARAMETER EndDate
    The end date for the audit logs.

.NOTES
    Author: Ankit Gupta
    GitHub: https://github.com/ankytgupta

    # Authentication can be done using a certificate (as below) or using a client secret:
    # Connect-MgGraph -ClientId $AppId -TenantId $TenantId -ClientSecret $ClientSecret
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$AppId,

    [Parameter(Mandatory = $true)]
    [string]$TenantId,

    [Parameter(Mandatory = $true)]
    [string]$CertThumbprint,

    [Parameter(Mandatory = $true)]
    [string]$StartDate,

    [Parameter(Mandatory = $true)]
    [string]$EndDate
)

# Connect using certificate-based authentication
Connect-MgGraph -ClientId $AppId -TenantId $TenantId -CertificateThumbprint $CertThumbprint -Scopes "AuditLog.Read.All"

# Get the audit logs
$auditLogs = Get-MgAuditLogDirectoryAudit -Filter "activityDateTime ge $StartDate and activityDateTime le $EndDate" -All
$auditLogs | Select-Object ActivityDateTime, ActivityDisplayName, InitiatedBy | Format-Table
