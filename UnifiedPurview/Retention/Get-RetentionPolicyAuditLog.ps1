<#
    .SYNOPSIS
        This script retrieves audit records related to retention policy changes in an Office 365 tenant.

    .DESCRIPTION
        The script connects to Exchange Online and Office 365 Compliance Center using certificate-based authentication.
        It searches for audit log records of retention policy updates within the last 30 days and exports the findings to CSV files.

    .NOTES
        Author: Ankit Gupta
        Last Modified: 2024-08-12
        Version: 1.0

    .EXAMPLE
        .\Get-RetentionPolicyAuditLog.PS1

        This example retrieves and analyzes retention policy updates within the last 30 days.
#>

# Certificate-based authentication details
$AppId = "Your-AppId-Here"
$TenantId = "Your-TenantId-Here"
$CertThumbprint = "Your-CertThumbprint-Here"

# Establish connections using certificate-based authentication
Connect-MgGraph -AppId $AppId -TenantId $TenantId -CertificateThumbprint $CertThumbprint -NoWelcome
Connect-ExchangeOnline -AppId $AppId -CertificateThumbprint $CertThumbprint -Organization $TenantId -ShowBanner:$False
Connect-IPPSSession -AppId $AppId -CertificateThumbprint $CertThumbprint -Organization $TenantId -ShowBanner:$False

# Verify that the Exchange Online module is loaded
$ModulesLoaded = Get-Module | Select-Object -ExpandProperty Name
If (!($ModulesLoaded -contains "ExchangeOnlineManagement")) {
    Write-Host "Please ensure the Exchange Online Management module is loaded, then restart the script."
    break
}

# Define date range for the audit log search (last 30 days)
$StartDate = (Get-Date).AddDays(-30)
$EndDate = (Get-Date)
$OutputCSVFile = "C:\DummyPath\RetentionPolicyUpdates.csv"
$AuditRulesReport = "C:\DummyPath\RetentionPolicyRulesUpdates.csv"

Write-Host "Retrieving Retention Policies from the tenant..."
# Build a hash table of retention policies for easy lookup by GUID
$RetentionPolicies = @{}
Try {
    [array]$RP = Get-RetentionCompliancePolicy
} Catch {
    Write-Host "Failed to fetch retention policies. Ensure the session is connected to the compliance endpoint."
    break
}

# Populate the hash table with policy GUIDs and names
$RP.ForEach({
    $RetentionPolicies.Add([String]$_.Guid, $_.Name)
})

# Repeat for application-specific retention policies (e.g., Teams, Yammer)
Try {
    [array]$RP = Get-AppRetentionCompliancePolicy
} Catch {
    Write-Host "Failed to fetch app-specific retention policies. Ensure the session is connected to the compliance endpoint."
    break
}

$RP.ForEach({
    $RetentionPolicies.Add([String]$_.Guid, $_.Name)
})

# Search for relevant audit log records
Write-Host "Searching for audit records related to retention policies..."
[array]$Records = Search-UnifiedAuditLog -Operations SetRetentionCompliancePolicy, SetRetentionComplianceRule -StartDate $StartDate -EndDate $EndDate -Formatted -ResultSize 2000
If (!($Records)) {
    Write-Host "No audit records found. Exiting script."
    break
}

# Filter records for policy updates
[array]$AuditRecords = $Records | Where-Object {$_.Operations -eq "SetRetentionCompliancePolicy"}

# Prepare to log retention rule changes
[array]$RuleRecords = $Records | Where-Object {$_.Operations -eq "SetRetentionComplianceRule"}
$AuditRules = [System.Collections.Generic.List[Object]]::new()
ForEach ($Rule in $RuleRecords) {
    $AuditData = $Rule.AuditData | ConvertFrom-Json
    $DataLine = [PSCustomObject]@{
        Date              = $Rule.CreationDate
        User              = $AuditData.UserId
        Policy            = $AuditData.ExtendedProperties | Where-Object {$_.Name -eq "PolicyName"} | Select-Object -ExpandProperty Value
        RetentionAction   = $AuditData.ExtendedProperties | Where-Object {$_.Name -eq "RetentionAction"} | Select-Object -ExpandProperty Value
        RetentionDuration = $AuditData.ExtendedProperties | Where-Object {$_.Name -eq "RetentionDuration"} | Select-Object -ExpandProperty Value
        RetentionType     = $AuditData.ExtendedProperties | Where-Object {$_.Name -eq "RetentionType"} | Select-Object -ExpandProperty Value
        Actions           = $AuditData.Parameters | Where-Object {$_.Name -eq "CmdletOptions"} | Select-Object -ExpandProperty Value
    }
    $AuditRules.Add($DataLine)
}

# Log policy update records
$AuditReport = [System.Collections.Generic.List[Object]]::new()
ForEach ($AuditRecord in $AuditRecords) {
    $AuditData = $AuditRecord.AuditData | ConvertFrom-Json
    $PolicyDetails = $AuditData.Parameters | Where-Object {$_.Name -eq "CmdletOptions"} | Select-Object -ExpandProperty Value

    $PolicyName = $null
    $PolicyGuid = $null
    $EncodedText = $null

    If ($PolicyDetails -Like "*RetryDistribution*") {
        # Handling retries for distribution to target locations
        $Start = $PolicyDetails.IndexOf('"') + 1
        $End = $PolicyDetails.IndexOf("-Retry") - 13
        $PolicyName = $PolicyDetails.SubString($Start, $End)
    } Else {
        # Regular policy update
        $Start = $PolicyDetails.IndexOf('"') + 1
        $EncodedText = $PolicyDetails.SubString($Start, 48)
        $PolicyGuid = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($EncodedText))
        $PolicyName = $RetentionPolicies.Item($PolicyGuid)
    }

    $DataLine = [PSCustomObject]@{
        Date          = $AuditRecord.CreationDate
        User          = $AuditData.UserId
        Policy        = $PolicyName
        PolicyGuid    = $PolicyGuid
        DetailsLogged = $PolicyDetails
        EC            = $EncodedText
    }
    $AuditReport.Add($DataLine)
}

# Export results to CSV files and display them
$AuditReport | Export-Csv -NoTypeInformation -Path $OutputCSVFile
$AuditRules | Export-Csv -NoTypeInformation -Path $AuditRulesReport
$AuditReport | Out-GridView
Write-Host "Process complete. Reports generated:"
Write-Host " - Policy update report: $OutputCSVFile"
Write-Host " - Audit rule updates report: $AuditRulesReport"
