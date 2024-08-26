<#
.SYNOPSIS
    Audits and reports on administrator activities within the Microsoft Purview Compliance Center.

.DESCRIPTION
    The Audit-AdminActivities script tracks and reports on all administrator activities 
    within the Microsoft Purview Compliance Center. It helps ensure that all actions taken by administrators 
    are documented and compliant with organizational policies.

.EXAMPLE
    .\Audit-AdminActivities.PS1
    This example runs the script to audit and report on administrator activities within the Purview Compliance Center.

.NOTES
    Author: Ankit Gupta
    Version: 1.1 - 25-Aug-2024
    GitHub Link: https://github.com/SecureAzCloud/Office365Scripts/blob/master/Audit-AdminActivities.PS1

    This script should be tested in a non-production environment before being used in production.
#>

# Connect to Purview Compliance Center
Connect-IPPSSession
# Note: You can authenticate using either certificate-based or client secret-based authentication.

# Define parameters
$StartDate = (Get-Date).AddMonths(-6)
$EndDate = Get-Date
$Operations = @("Add-Admin", "Remove-Admin", "Update-AdminPermissions")

# Retrieve admin activities
$adminActivities = Search-UnifiedAuditLog -StartDate $StartDate -EndDate $EndDate -Operations $Operations -ResultSize 5000

# Export to CSV
$adminActivities | Export-Csv -Path "C:\Reports\AdminActivities.csv" -NoTypeInformation

Write-Host "Admin activities have been exported to C:\Reports\AdminActivities.csv."

# Disconnect the session
Disconnect-IPPSSession
