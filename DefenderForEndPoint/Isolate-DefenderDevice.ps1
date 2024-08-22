<#
.SYNOPSIS
    Isolate a device using Microsoft Defender for Endpoint.

.DESCRIPTION
    This script uses Microsoft Graph API to isolate a device from the network for security reasons.

.PARAMETER DeviceId
    The unique identifier of the device to isolate.

.PARAMETER AppId
    The Application (client) ID of the Azure AD app.

.PARAMETER TenantId
    The Directory (tenant) ID.

.PARAMETER CertThumbprint
    The certificate thumbprint for authentication.

.EXAMPLE
    .\Isolate-DefenderDevice.ps1 -DeviceId "YourDeviceId" -AppId "YourAppId" -TenantId "YourTenantId" -CertThumbprint "YourCertThumbprint"

#>
param (
    [Parameter(Mandatory = $true)]
    [string]$DeviceId,

    [Parameter(Mandatory = $true)]
    [string]$AppId,

    [Parameter(Mandatory = $true)]
    [string]$TenantId,

    [Parameter(Mandatory = $true)]
    [string]$CertThumbprint
)

Connect-MgGraph -AppId $AppId -TenantId $TenantId -CertificateThumbprint $CertThumbprint -Scopes "DeviceManagementManagedDevices.ReadWrite.All" -NoWelcome

# Example using client secret (uncomment to use):
# Connect-MgGraph -ClientId $AppId -TenantId $TenantId -ClientSecret "YourClientSecret" -Scopes "DeviceManagementManagedDevices.ReadWrite.All" -NoWelcome

Write-Host "Isolating device..."
Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$DeviceId/isolate" -Method POST

Disconnect-MgGraph
