<#
.SYNOPSIS
    This script retrieves and processes audit records for failed sign-in attempts within the last 90 days.

.DESCRIPTION
    The ReportAuditRecFailedSignIn script queries Microsoft 365 audit logs to identify and report failed sign-in attempts. 
    The script connects to Exchange Online, fetches relevant audit records, and processes them to produce a detailed report 
    on failed login activities, including user information, timestamps, IP addresses, and error details.

.EXAMPLE
    .\Get-FailedSignins.ps1
    This example runs the script to retrieve failed sign-in audit logs and displays the results in an Out-GridView window.

.NOTES
    Author: Ankit Gupta
    Version: 1.1 - 28-Aug-2024
    GitHub Link: https://github.com/SecureAzCloud/Office365Scripts/blob/master/ReportAuditRecFailedSignIn.PS1

    Always validate and test scripts in a non-production environment before deploying them in your organization.

#>

# Ensure that the necessary modules are loaded
$ModulesLoaded = Get-Module | Select-Object -ExpandProperty Name
If ("ExchangeOnlineManagement" -notin $ModulesLoaded) {
    Write-Host "Initializing connection to Exchange Online..."
    Connect-ExchangeOnline -SkipLoadingCmdletHelp
}

# Query audit logs for failed user login attempts within the last 90 days
Write-Host "Querying audit logs for failed sign-in attempts..."
[array]$AuditRecords = Search-UnifiedAuditLog -StartDate (Get-Date).AddDays(-90) -EndDate (Get-Date).AddDays(+1) `
  -Operations UserLoginFailed -SessionCommand ReturnLargeSet -ResultSize 5000 -Formatted
If ($AuditRecords.Count -eq 0) {
  Write-Host "No failed sign-in audit records found." 
  break
}

# Remove duplicates and sort the records by date
$AuditRecords = $AuditRecords | Sort-Object Identity -Unique | Sort-Object { $_.CreationDate -as [datetime]} -Descending
 
Write-Host ("Processing {0} audit records for failed sign-ins..." -f $AuditRecords.Count)
$FailedSignInReport = [System.Collections.Generic.List[Object]]::new()
ForEach ($Record in $AuditRecords) {
  $AuditData = ConvertFrom-Json $Record.AuditData
  $ReportEntry = [PSCustomObject]@{
    TimeStamp   = $Record.CreationDate
    User        = $AuditData.UserId
    Action      = $AuditData.Operation
    Status      = $AuditData.ResultStatus
    IpAddress   = $AuditData.ActorIpAddress
    Error       = $AuditData.LogonError
    UserAgent   = $AuditData.ExtendedProperties.value[0] 
  }
  $FailedSignInReport.Add($ReportEntry) 
}

# Display the processed report in an Out-GridView window
$FailedSignInReport | Sort-Object User, Timestamp | Select-Object Timestamp, User, IpAddress, UserAgent | Out-GridView

# Example script demonstrating the retrieval and reporting of audit logs for failed sign-ins.
# Always ensure to validate and test any scripts in a safe, non-production environment before deployment.
