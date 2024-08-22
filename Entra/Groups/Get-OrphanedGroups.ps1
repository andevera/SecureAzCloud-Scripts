<#
.SYNOPSIS
    Retrieves orphaned groups in Entra ID (groups without an owner).

.DESCRIPTION
    This script finds all groups in Entra ID that do not have an assigned owner.

.EXAMPLE
    .\Get-OrphanedGroups.ps1

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

# Get all groups
$groups = Get-MgGroup -All

# Filter for orphaned groups
$orphanedGroups = foreach ($group in $groups) {
    $owners = Get-MgGroupOwner -GroupId $group.Id
    if ($owners.Count -eq 0) {
        $group
    }
}

$orphanedGroups | Select-Object DisplayName, Description, Id | Format-Table
