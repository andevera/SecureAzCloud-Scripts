<#
.SYNOPSIS
    Automates the assignment of licenses to users based on group membership.

.DESCRIPTION
    This script assigns or removes licenses to users in Entra ID based on their group membership.

.EXAMPLE
    .\Automate-LicenseAssignment.ps1 -GroupId "12345abc-de67-890f-gh12-34567ijkl890"

.PARAMETER GroupId
    The ID of the group used to assign licenses.

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
    [string]$GroupId
)

# Connect using certificate-based authentication
Connect-MgGraph -ClientId $AppId -TenantId $TenantId -CertificateThumbprint $CertThumbprint -Scopes "Directory.ReadWrite.All"

# Get the group members
$members = Get-MgGroupMember -GroupId $GroupId -All

# Define the SKU ID for the license to assign
$skuId = "abcd1234-5678-90ef-gh12-3456ijkl7890" # Replace with your SKU ID

foreach ($member in $members) {
    $userId = $member.Id

    # Check if the user already has the license
    $userLicenses = Get-MgUserLicenseDetail -UserId $userId
    if ($userLicenses.SkuId -contains $skuId) {
        Write-Output "User $($member.UserPrincipalName) already has the license."
    } else {
        # Assign the license
        Add-MgUserLicense -UserId $userId -AddLicenses @($skuId)
        Write-Output "License assigned to user $($member.UserPrincipalName)."
    }
}
