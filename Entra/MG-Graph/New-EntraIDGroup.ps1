<#
.SYNOPSIS
    Creates a new security group in Entra ID.

.DESCRIPTION
    This script creates a new security group in Entra ID with the specified display name and description.

.EXAMPLE
    .\New-EntraIDGroup.ps1 -DisplayName "Marketing Team" -Description "Group for the marketing team."

.PARAMETER DisplayName
    The display name of the new group.

.PARAMETER Description
    The description of the new group.

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
Connect-MgGraph -ClientId $AppId -TenantId $TenantId -CertificateThumbprint $CertThumbprint -Scopes Group.ReadWrite.All

# Create a new group
New-MgGroup -DisplayName $DisplayName -Description $Description -MailEnabled $false -SecurityEnabled $true -MailNickname $DisplayName.Replace(" ", "")
Write-Output "Group '$DisplayName' created successfully."
