<#
.SYNOPSIS
    Retrieves all users from Entra ID.

.DESCRIPTION
    This script retrieves all users from Entra ID and outputs their display name, user principal name (UPN), and account status.

.EXAMPLE
    .\Get-EntraIDUsers.ps1

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
    [string]$CertThumbprint
)

# Connect using certificate-based authentication
Connect-MgGraph -ClientId $AppId -TenantId $TenantId -CertificateThumbprint $CertThumbprint -Scopes "User.Read.All"

# Retrieve all users
$users = Get-MgUser -All -ConsistencyLevel eventual -CountVariable Count | Select-Object DisplayName, UserPrincipalName, AccountEnabled
$users | Format-Table
Write-Output "Total users retrieved: $Count"
