<#
.SYNOPSIS
    Monitors Data Loss Prevention (DLP) alerts and generates a report of incidents.

.DESCRIPTION
    The Monitor-DLPAlerts script retrieves Data Loss Prevention (DLP) alerts from the Purview Compliance Center 
    and generates a detailed report of incidents. It helps administrators stay informed of potential data breaches 
    or sensitive data exposure within the organization.

.EXAMPLE
    .\Monitor-DLPAlerts.PS1
    This example runs the script to monitor DLP alerts and generate a report of incidents.

.NOTES
    Author: Ankit Gupta
    Version: 1.1 - 25-Aug-2024
    GitHub Link: https://github.com/SecureAzCloud/Office365Scripts/blob/master/Monitor-DLPAlerts.PS1

    This script should be tested in a non-production environment before being used in production.
#>

# Connect to Purview Compliance Center
Connect-IPPSSession
# Note: You can authenticate using either certificate-based or client secret-based authentication.

# Define parameters
$StartDate = (Get-Date).AddDays(-30)
$EndDate = Get-Date

# Retrieve DLP alerts
$dlpAlerts = Get-DlpAlert -StartDate $StartDate -EndDate $EndDate -Severity High

# Export the alerts to a CSV file
$dlpAlerts | Export-Csv -Path "C:\Reports\DLPAlerts.csv" -NoTypeInformation

Write-Host "DLP alerts have been exported to C:\Reports\DLPAlerts.csv."

# Disconnect the session
Disconnect-IPPSSession
