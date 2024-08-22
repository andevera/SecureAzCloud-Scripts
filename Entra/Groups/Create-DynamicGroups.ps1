<#
.SYNOPSIS
    Creates dynamic groups in Entra ID based on user attributes.

.DESCRIPTION
    This script creates dynamic Entra ID groups that automatically include users based on specific attribute values.

.EXAMPLE
    .\Create-DynamicGroups.ps1 -GroupName "Sales Team" -UserAttribute "Department" -AttributeValue "Sales"

.PARAMETER GroupName
    The name of the dynamic group to create.

.PARAMETER UserAttribute
    The user attribute to filter by (e.g., Department, JobTitle).

.PARAMETER AttributeValue
    The value of the user attribute to match for group membership.

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
    [string]$GroupName,

    [Parameter(Mandatory = $true)]
    [string]$UserAttribute,

    [Parameter(Mandatory = $true)]
    [string]$AttributeValue
)

# Connect using certificate-based authentication
Connect-MgGraph -ClientId $AppId -TenantId $TenantId -CertificateThumbprint $CertThumbprint -Scopes "Group.ReadWrite.All"

# Create the dynamic group
$dynamicMembershipRule = "($UserAttribute -eq `"$AttributeValue`")"
$group = @{
    DisplayName = $GroupName
    MailEnabled = $false
    SecurityEnabled = $true
    GroupTypes = @("DynamicMembership")
    MembershipRule = $dynamicMembershipRule
    MembershipRuleProcessingState = "On"
}
New-MgGroup -BodyParameter $group
Write-Output "Dynamic group '$GroupName' created successfully with rule '$dynamicMembershipRule'."
