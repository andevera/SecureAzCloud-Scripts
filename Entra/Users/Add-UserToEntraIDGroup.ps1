<#
.SYNOPSIS
    Adds a user to a specific group in Entra ID.

.DESCRIPTION
    This script assigns a user to a specified Entra ID group.

.EXAMPLE
    .\Add-UserToEntraIDGroup.ps1 -UserPrincipalName "jdoe@example.com" -GroupId "f4c5b2b1-7d3a-4316-b7a2-1a2b3c4d5e6f"

.PARAMETER UserPrincipalName
    The UPN of the user to add to the group.

.PARAMETER GroupId
    The ID of the group to add the user to.

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
    [string]$UserPrincipalName,

    [Parameter(Mandatory = $true)]
    [string]$GroupId
)

# Connect using certificate-based authentication
Connect-MgGraph -ClientId $AppId -TenantId $TenantId -CertificateThumbprint $CertThumbprint -Scopes "GroupMember.ReadWrite.All"

# Get the user and add them to the group
$user = Get-MgUser -UserPrincipalName $UserPrincipalName
Add-MgGroupMember -GroupId $GroupId -AdditionalProperties @{'@odata.id'="https://graph.microsoft.com/v1.0/users/$($user.Id)"}
Write-Output "User '$UserPrincipalName' added to group '$GroupId' successfully."
