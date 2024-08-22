<#
.SYNOPSIS
    Lists all teams in Microsoft Teams.

.DESCRIPTION
    This script retrieves all the teams within an organization and displays their display name and description.

.EXAMPLE
    .\Get-Teams.ps1

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
Connect-MgGraph -ClientId $AppId -TenantId $TenantId -CertificateThumbprint $CertThumbprint -Scopes "Team.ReadBasic.All"

# List all teams
$teams = Get-MgTeam -All -ConsistencyLevel eventual -CountVariable Count | Select-Object DisplayName, Description
$teams | Format-Table
Write-Output "Total teams retrieved: $Count"
