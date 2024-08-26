<#
.SYNOPSIS
    Tracks and reports on data lifecycle events in Microsoft 365.

.DESCRIPTION
    The Track-DataLifecycleEvents script monitors data lifecycle events such as document deletion, 
    retention policy actions, and content expiration within Microsoft 365. It generates a report 
    detailing these events for compliance review.

.EXAMPLE
    .\Track-DataLifecycleEvents.PS1
    This example runs the script to track and report on data lifecycle events in Microsoft 365.

.NOTES
    Author: Ankit Gupta
    Version: 1.1 - 25-Aug-2024
    GitHub Link: https://github.com/SecureAzCloud/Office365Scripts/blob/master/Track-DataLifecycleEvents.PS1

    This script should be tested in a non-production environment before being used in production.
#>

# Connect to Purview Compliance Center
Connect-IPPSSession
# Note: You can authenticate using either certificate-based or client secret-based authentication.

# Define parameters
$StartDate = (Get-Date).AddMonths(-6)
$EndDate = Get-Date
$Operations = @("FileDeleted", "RetentionLabelApplied", "RetentionLabelRemoved")

# Retrieve data lifecycle events
$lifecycleEvents = Search-UnifiedAuditLog -StartDate $StartDate -EndDate $EndDate -Operations $Operations -ResultSize 5000

# Export to CSV
$lifecycleEvents | Export-Csv -Path "C:\Reports\DataLifecycleEvents.csv" -NoTypeInformation

Write-Host "Data lifecycle events have been exported to C:\Reports\DataLifecycleEvents.csv."

# Disconnect the session
Disconnect-IPPSSession
