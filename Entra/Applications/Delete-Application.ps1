<#
.SYNOPSIS
    Deletes an application from Entra ID.

.DESCRIPTION
    This script deletes an application from Entra ID.

.EXAMPLE
    .\Delete-Application.ps1 -AppId "12345abc-de67-890f-gh12-34567ijkl890"

.PARAMETER AppId
    The application ID of the application to delete.

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
Connect-MgGraph -ClientId $AppId -TenantId $TenantId -CertificateThumbprint $CertThumbprint -Scopes "Application.ReadWrite.All"

# Delete the application
Remove-MgApplication -ApplicationId $AppId
Write-Output "Application '$AppId' deleted successfully."
