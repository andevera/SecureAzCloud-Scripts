<#
.SYNOPSIS
    Retrieve a list of devices registered with Microsoft Defender for Endpoint.

.DESCRIPTION
    This script uses Microsoft Graph API to retrieve information about devices registered in Microsoft Defender for Endpoint.

.PARAMETER AppId
    The Application (client) ID of the Azure AD app.

.PARAMETER TenantId
    The Directory (tenant) ID.

.PARAMETER CertThumbprint
    The certificate thumbprint for authentication.

.EXAMPLE
    .\Get-DefenderDevices.ps1 -AppId "YourAppId" -TenantId "YourTenantId" -CertThumbprint "YourCertThumbprint"

#>
param (
    [Parameter(Mandatory = $true)]
    [string]$AppId,

    [Parameter(Mandatory = $true)]
    [string]$TenantId,

    [Parameter(Mandatory = $true)]
    [string]$CertThumbprint
)

# Use certificate-based authentication
Connect-MgGraph -AppId $AppId -TenantId $TenantId -CertificateThumbprint $CertThumbprint -Scopes "Device.Read.All" -NoWelcome

# Example using client secret (uncomment to use):
# Connect-MgGraph -ClientId $AppId -TenantId $TenantId -ClientSecret "YourClientSecret" -Scopes "Device.Read.All" -NoWelcome

Write-Host "Retrieving devices..."
$devices = Get-MgDevice -All

$devices | Select-Object Id, DisplayName, OperatingSystem, ComplianceState | Format-Table

Disconnect-MgGraph
