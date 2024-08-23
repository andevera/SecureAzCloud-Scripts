<#
.SYNOPSIS
    Retrieve Local Administrator Password Solution (LAPS) passwords for a specified device using Microsoft Graph.

.DESCRIPTION
    This script retrieves the Local Administrator Password Solution (LAPS) passwords for a specific device from Entra ID (formerly Azure AD). 
    It allows you to authenticate using user credentials or a client application with appropriate permissions.

.PARAMETER TenantID
    The Directory (tenant) ID.

.PARAMETER LAPSAppID
    The Application (client) ID for the LAPS app.

.PARAMETER DeviceName
    The name of the device for which to retrieve the LAPS password.

.EXAMPLE
    .\Get-LAPSPassword.ps1 -TenantID "YourTenantID" -LAPSAppID "YourLAPSAppID" -DeviceName "cl01"

.NOTES
    Author: Ankit Gupta
    GitHub: https://github.com/AnkitGupta/SecureAzCloud-Scripts
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$TenantID,

    [Parameter(Mandatory = $true)]
    [string]$LAPSAppID,

    [Parameter(Mandatory = $true)]
    [string]$DeviceName
)

# Install Microsoft Graph module if not already installed
if (-not (Get-Module -Name "Microsoft.Graph" -ListAvailable)) {
    Install-Module -Name "Microsoft.Graph" -Scope AllUsers -Force
}

# Connect to Microsoft Graph using the provided Tenant ID and Application ID
# Note: This example uses client ID. Uncomment the below line to use certificate-based authentication
# Connect-MgGraph -TenantID $TenantID -ClientID $LAPSAppID -CertificateThumbprint "YourCertificateThumbprint" -Scopes "Device.Read.All","DeviceLocalCredential.Read.All" -NoWelcome

# Alternatively, you could use client secret (uncomment the below line)
# Connect-MgGraph -TenantID $TenantID -ClientID $LAPSAppID -ClientSecret "YourClientSecret" -Scopes "Device.Read.All","DeviceLocalCredential.Read.All" -NoWelcome

# Authenticate with necessary permissions for Device and Local Credential access
Connect-MgGraph -TenantID $TenantID -ClientID $LAPSAppID -Scopes "Device.Read.All","DeviceLocalCredential.Read.All" -NoWelcome

# Fetch the device ID for the specified device name
$devDetails = Get-MgDevice -Search "displayName:$DeviceName" -ConsistencyLevel eventual
if ($devDetails -eq $null) {
    Write-Output "Device not found. Ensure the device name is correct."
    return
}

$deviceId = $devDetails.Id

# Retrieve the LAPS password for the device
$response = Invoke-MgGraphRequest -Method Get -Uri "https://graph.microsoft.com/beta/deviceLocalCredentials/$deviceId?`$select=credentials"

if ($response -and $response.credentials) {
    $passwordBase64 = $response.credentials[0].passwordBase64
    $passwordPlainText = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($passwordBase64))
    Write-Output "LAPS Password for device $DeviceName: $passwordPlainText"
} else {
    Write-Output "No credentials found for device $DeviceName."
}

Disconnect-MgGraph
