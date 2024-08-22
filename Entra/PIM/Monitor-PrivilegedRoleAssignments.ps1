<#
.SYNOPSIS
    Monitors and alerts on privileged role assignments in Entra ID.

.DESCRIPTION
    This script monitors for privileged role assignments in Entra ID and sends an alert if a new assignment is detected.

.EXAMPLE
    .\Monitor-PrivilegedRoleAssignments.ps1 -Email "admin@example.com"

.PARAMETER Email
    The email address to send alerts to.

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
    [string]$Email
)

# Connect using certificate-based authentication
Connect-MgGraph -ClientId $AppId -TenantId $TenantId -CertificateThumbprint $CertThumbprint -Scopes "RoleManagement.Read.All"

# Get current privileged role assignments
$currentAssignments = Get-MgRoleManagementDirectoryRoleAssignment -Filter "roleDefinitionId eq '62e90394-69f5-4237-9190-012177145e10'" -All

# Save current assignments to a local file (for first-time run)
$localFile = "C:\Temp\PrivilegedRoleAssignments.json"
if (-not (Test-Path $localFile)) {
    $currentAssignments | ConvertTo-Json | Out-File $localFile
}

# Compare with previous assignments
$previousAssignments = Get-Content $localFile | ConvertFrom-Json
$newAssignments = Compare-Object $previousAssignments $currentAssignments -Property Id

if ($newAssignments) {
    $newAssignments | ForEach-Object {
        $message = "New privileged role assignment detected for user $($_.PrincipalDisplayName)."
        Send-MailMessage -To $Email -Subject "Alert: New Privileged Role Assignment" -Body $message -SmtpServer "smtp.example.com"
        Write-Output $message
    }

    # Update local file with current assignments
    $currentAssignments | ConvertTo-Json | Out-File $localFile
} else {
    Write-Output "No new privileged role assignments detected."
}
