<#
.SYNOPSIS
    Creates a new team in Microsoft Teams.

.DESCRIPTION
    This script creates a new team with the specified display name and description.

.EXAMPLE
    .\New-Team.ps1 -DisplayName "Marketing Team" -Description "Team for the marketing department."

.PARAMETER DisplayName
    The display name of the new team.

.PARAMETER Description
    The description of the new team.

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
    [string]$DisplayName,

    [Parameter(Mandatory = $true)]
    [string]$Description
)

# Connect using certificate-based authentication
Connect-MgGraph -ClientId $AppId -TenantId $TenantId -CertificateThumbprint $CertThumbprint
