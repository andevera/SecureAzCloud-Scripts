<#
    .SYNOPSIS
        This script provides an analysis of sensitivity label usage across an Office 365 tenant by extracting and processing audit log data.

    .DESCRIPTION
        The script leverages certificate-based authentication to connect to Microsoft Graph, Exchange Online, and IPPSSession.
        It retrieves audit log records related to sensitivity label operations and processes this data to give insights into label usage trends.
        This includes identifying the most frequently applied labels and the users who most commonly apply them.

    .NOTES
        Author: Ankit Gupta
        Last Modified: 2024-08-12
        Version: 1.0

    .EXAMPLE
        .\Get-SensitivityLabelsUsage.PS1

        This example retrieves and analyzes the sensitivity label usage within your Office 365 tenant over the past 90 days.
#>

# Certificate-based authentication details
$AppId = "Your-AppId-Here"
$TenantId = "Your-TenantId-Here"
$CertThumbprint = "Your-CertThumbprint-Here"

# Establish connections using certificate-based authentication
Connect-MgGraph -AppId $AppId -TenantId $TenantId -CertificateThumbprint $CertThumbprint -NoWelcome
Connect-ExchangeOnline -AppId $AppId -CertificateThumbprint $CertThumbprint -Organization $TenantId -ShowBanner:$False
Connect-IPPSSession -AppId $AppId -CertificateThumbprint $CertThumbprint -Organization $TenantId -ShowBanner:$False

# Notify user that sensitivity labels are being retrieved
Write-Host "Fetching sensitivity labels available in the tenant..."
$SensitivityLabels = @{}
[array]$LabelCollection = Get-Label | Select-Object ImmutableId, DisplayName
If (!($LabelCollection)) { Write-Host "No sensitivity labels found. Exiting script."; break }
ForEach ($Label in $LabelCollection) { $SensitivityLabels.Add([string]$Label.ImmutableId, [string]$Label.DisplayName) }

# Define the operations to track
$LabelOperations = ("SensitivityLabelUpdated", "SensitivityLabelApplied", "FileSensitivityLabelApplied", "MIPLabel")
$AuditStartDate = (Get-Date).AddDays(-90)
$AuditEndDate = (Get-Date).AddDays(1)
Write-Host "Gathering audit records for sensitivity label operations..."
[Array]$AuditRecords = Search-UnifiedAuditLog -StartDate $AuditStartDate -EndDate $AuditEndDate -Formatted -ResultSize 5000 -Operations $LabelOperations
If (!($AuditRecords)) { Write-Host "No relevant audit records found. Exiting."; break }

$AuditRecords = $AuditRecords | Where-Object {$_.RecordType -ne "ComplianceDLPExchange"}
$LabelUsageReport = [System.Collections.Generic.List[Object]]::new() 

# Process each audit record to extract relevant details
ForEach ($Record in $AuditRecords) {
   $AuditDetails = $Record.AuditData | ConvertFrom-Json
   $LabelRemoved = $Null; $LabelAdded = $Null; $EventType = $Null; $LabelRemoved = $Null; $FileName = $Null; $SiteUrl = $Null

   If ($AuditDetails.Application -ne "Outlook") {
   Switch ($Record.Operations) {
    "FileSensitivityLabelApplied" {
      $EventType = "Policy applied default label"
      $LabelAdded = $SensitivityLabels[$AuditDetails.DestinationLabel]
      $Application = $AuditDetails.Workload
      $ObjectId = $AuditDetails.ObjectId
      $FileName = $AuditDetails.DestinationFileName 
      $SiteUrl = $AuditDetails.SiteUrl
    }   
    "SensitivityLabelApplied" {
     $EventType = "User assigned label"
     $LabelAdded = $SensitivityLabels[$AuditDetails.SensitivityLabelEventData.SensitivityLabelId]
     $Application = $AuditDetails.Application
     $ObjectId = [System.Web.HttpUtility]::UrlDecode($AuditDetails.ObjectId)
     $FileName = $ObjectId.Split('/')[-1]	
     $SiteUrl = "https://" + $ObjectId.Split("/")[2] + "/sites/" + $ObjectId.Split("/")[4] + "/"
    }
     "SensitivityLabelUpdated" {
     $EventType = "User updated label"
     $LabelAdded = $SensitivityLabels[$AuditDetails.SensitivityLabelEventData.SensitivityLabelId]
     $LabelRemoved = $SensitivityLabels[$AuditDetails.SensitivityLabelEventData.OldSensitivityLabelId]
     $Application = $AuditDetails.Application
     $ObjectId =  [System.Web.HttpUtility]::UrlDecode($AuditDetails.ObjectId)
     $FileName = $ObjectId.Split('/')[-1]
     $SiteUrl = "https://" + $ObjectId.Split("/")[2] + "/sites/" + $ObjectId.Split("/")[4] + "/"
    }
    "MIPLabel" {
     $EventType = "Email labeled in Exchange Online"
     $LabelAdded = $SensitivityLabels[$AuditDetails.LabelId]
     $Application = "Exchange Online"
     $ObjectId = "Email"
     $FileName = "Email"
     $SiteUrl = "N/A"
     }
   } #End Switch

 If ($UserId -eq "app@sharepoint") {
     $EventType = "Label applied by document library default" 
 } ElseIf ($UserId -eq "SHAREPOINT\system") { 
   $EventType = "Label applied by auto-label policy" }
 If ($ObjectId -like "*/personal/*") { # Adjust for OneDrive URLs
    $SiteUrl = "https://" + $ObjectId.Split("/")[2] + "/personal/" + $ObjectId.Split("/")[4] + "/" }

  $DataEntry = [PSCustomObject] @{
       Timestamp    = Get-Date($Record.CreationDate) -format g
       User         = $AuditDetails.UserId
       Operation    = $Record.Operations
       LabelAdded   = $LabelAdded
       LabelRemoved = $LabelRemoved
       Application  = $Application
       EventType    = $EventType
       Site         = $SiteUrl
       Object       = $ObjectId
       Item         = $FileName } 

 $LabelUsageReport.Add($DataEntry) 
 } #End if
} # End ForEach

# Output analysis of the label usage
Write-Host ""
Write-Host "Summary of the most frequently used sensitivity labels:"
Write-Host "--------------------------------------------------------"
$LabelUsageReport | Group-Object LabelAdded | Sort-Object Count -Descending | Format-Table Name, Count

Write-Host ""
Write-Host "Users who applied sensitivity labels most frequently:"
Write-Host "------------------------------------------------------"
$LabelUsageReport | Group-Object User | Sort-Object Count -Descending | Format-Table Name, Count

# Display the report in a grid view for further analysis
$LabelUsageReport | Out-GridView
