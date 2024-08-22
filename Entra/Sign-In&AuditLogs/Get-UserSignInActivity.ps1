<#
.SYNOPSIS
    Lists sign-in activities for a specific user.

.DESCRIPTION
    This script lists sign-in activities for a specified user over a given time period.

.EXAMPLE
    .\Get-UserSignInActivity.ps1 -UserPrincipalName "jdoe@example.com" -StartDate "2024-08-01T00:00:00Z" -EndDate "2024-08-07T23:59:59Z"

.PARAMETER UserPrincipalName
    The UPN of the user to retrieve sign-in activities for.

.PARAMETER StartDate
    The start date for the sign-in logs.

.PARAMETER EndDate
    The end date for the sign-in logs.

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
    [string]$UserPrincipalName,

    [Parameter(Mandatory = $true)]
    [string]$StartDate,

    [Parameter(Mandatory = $true)]
    [string]$EndDate
)

# Connect using certificate-based authentication
Connect-MgGraph -ClientId $AppId -TenantId $TenantId -CertificateThumbprint $CertThumbprint -Scopes "AuditLog.Read.All"

# Get sign-in activities for the user
$signInLogs = Get-MgAuditLogSignIn -Filter "userPrincipalName eq '$UserPrincipalName' and createdDateTime ge $StartDate and createdDateTime le $EndDate" -All
$signInLogs | Select-Object CreatedDateTime, UserDisplayName, UserPrincipalName, AppDisplayName, Status | Format-Table
