<#
.SYNOPSIS
    Creates multiple users in Entra ID from a CSV file.

.DESCRIPTION
    This script reads user details from a CSV file and creates users in Entra ID.

.EXAMPLE
    .\Create-BulkUsers.ps1 -CSVPath "C:\UsersToCreate.csv"

.PARAMETER CSVPath
    The file path to the CSV containing user details.

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
    [string]$CSVPath
)

# Connect using certificate-based authentication
Connect-MgGraph -ClientId $AppId -TenantId $TenantId -CertificateThumbprint $CertThumbprint -Scopes "User.ReadWrite.All"

# Import users from CSV
$users = Import-Csv -Path $CSVPath

# Loop through each user and create them in Entra ID
foreach ($user in $users) {
    New-MgUser -DisplayName $user.DisplayName -UserPrincipalName $user.UserPrincipalName `
        -AccountEnabled $true -MailNickname $user.MailNickname `
        -PasswordProfile @{Password=$user.Password; ForceChangePasswordNextSignIn=$true} `
        -UsageLocation $user.UsageLocation -GivenName $user.GivenName -Surname $user.Surname
    Write-Output "User $($user.UserPrincipalName) created successfully."
}
