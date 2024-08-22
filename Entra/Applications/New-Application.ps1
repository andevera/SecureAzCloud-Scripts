<#
.SYNOPSIS
    Creates a new application in Entra ID.

.DESCRIPTION
    This script creates a new application with the specified display name in Entra ID.

.EXAMPLE
    .\New-Application.ps1 -DisplayName "My New Application"

.PARAMETER DisplayName
    The display name of the new application.

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
    [string]$DisplayName
)

# Connect using certificate-based authentication
Connect-MgGraph -ClientId $AppId -TenantId $TenantId -CertificateThumbprint $CertThumbprint -Scopes "Application.ReadWrite.All"

# Create a new application
New-MgApplication -DisplayName $DisplayName
Write-Output "Application '$DisplayName' created successfully."
