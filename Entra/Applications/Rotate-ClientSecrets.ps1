<#
.SYNOPSIS
    Rotates client secrets for Entra ID app registrations.

.DESCRIPTION
    This script generates new client secrets for specified Entra ID app registrations and updates them.

.EXAMPLE
    .\Rotate-ClientSecrets.ps1 -AppId "12345678-90ab-cdef-1234-567890abcdef" -SecretName "NewSecret"

.PARAMETER AppId
    The ID of the application to rotate the secret for.

.PARAMETER SecretName
    The name of the new client secret.

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
    [string]$AppIdToUpdate,

    [Parameter(Mandatory = $true)]
    [string]$SecretName
)

# Connect using certificate-based authentication
Connect-MgGraph -ClientId $AppId -TenantId $TenantId -CertificateThumbprint $CertThumbprint -Scopes "Application.ReadWrite.OwnedBy"

# Create new client secret
$secretValue = [System.Web.Security.Membership]::GeneratePassword(32, 8)
$expiryDate = (Get-Date).AddYears(2)
$clientSecret = @{
    displayName = $SecretName
    secretText = $secretValue
    endDateTime = $expiryDate
}

# Update app registration with new client secret
Add-MgApplicationPassword -ApplicationId $AppIdToUpdate -BodyParameter $clientSecret
Write-Output "New client secret created for App ID '$AppIdToUpdate' with name '$SecretName'."
