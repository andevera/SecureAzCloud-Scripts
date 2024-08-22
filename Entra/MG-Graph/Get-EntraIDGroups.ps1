<#
.SYNOPSIS
    Retrieves all groups from Entra ID.

.DESCRIPTION
    This script retrieves all groups from Entra ID and outputs their display name, group type, and membership type.

.EXAMPLE
    .\Get-EntraIDGroups.ps1

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
Connect-MgGraph -ClientId $AppId -TenantId $TenantId -CertificateThumbprint $CertThumbprint -Scopes "Group.Read.All"

# Retrieve all groups
$groups = Get-MgGroup -All -ConsistencyLevel eventual -CountVariable Count | Select-Object DisplayName, GroupTypes, MembershipRule
$groups | Format-Table
Write-Output "Total groups retrieved: $Count"
