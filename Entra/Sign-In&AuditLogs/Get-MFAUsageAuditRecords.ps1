<#
    .SYNOPSIS
        This script retrieves and analyzes Entra ID sign-in audit records to assess Multi-Factor Authentication (MFA) usage by user accounts.

    .DESCRIPTION
        The script connects to Microsoft Graph using certificate-based authentication and retrieves sign-in audit logs. 
        It checks whether users have performed MFA during their sign-ins and generates a report summarizing MFA usage across the tenant.

    .NOTES
        Author: Ankit Gupta
        Last Modified: 2024-08-12
        Version: 1.0

    .EXAMPLE
        .\Get-MFAUsageAuditRecords.PS1

        This example retrieves and analyzes MFA usage based on sign-in audit logs within the last 15 days.
#>

# Certificate-based authentication details
$AppId = "Your-AppId-Here"
$TenantId = "Your-TenantId-Here"
$CertThumbprint = "Your-CertThumbprint-Here"

# Establish connections using certificate-based authentication
Connect-MgGraph -AppId $AppId -TenantId $TenantId -CertificateThumbprint $CertThumbprint -Scopes Directory.Read.All, AuditLog.Read.All -NoWelcome

# Define the output file path
$CSVOutputFile = "C:\DummyPath\CheckAuditRecordsMFA.csv"
$TenantId = (Get-MgOrganization).Id
$StartDate = (Get-Date).AddDays(-15)
$StartDateS = (Get-Date $StartDate -Format s) + "Z"

Write-Host "Fetching sign-in records from the past 15 days..."
[array]$AuditRecords = Get-MgBetaAuditLogSignIn -Top 5000 `
  -Filter "(CreatedDateTime ge $StartDateS) and (signInEventTypes/any(t:t eq 'interactiveuser')) and (usertype eq 'Member')"

If (!$AuditRecords) {
    Write-Host "No sign-in records found. Exiting script."
    Break
}

# Filter out sign-ins from other tenants
$AuditRecords = $AuditRecords | Where-Object HomeTenantId -eq $TenantId

Write-Host "Retrieving user accounts..."
[array]$Users = Get-MgUser -All -Sort 'displayName' `
    -Filter "assignedLicenses/`$count ne 0 and userType eq 'Member'" -ConsistencyLevel Eventual -CountVariable UsersFound `
    -Property Id, displayName, signInActivity, userPrincipalName

Write-Host ("Analyzing {0} sign-in audit records for {1} user accounts..." -f $AuditRecords.Count, $Users.Count)
[int]$MFAUsers = 0
$Report = [System.Collections.Generic.List[Object]]::new()

ForEach ($User in $Users) {
    $Authentication = "No sign-in records found"
    $Status = $null
    $MFARecordDateTime = $null
    $MFAMethodsUsed = $null
    $MFAStatus = $null
    $UserLastSignInDate = $null
    [array]$UserAuditRecords = $AuditRecords | Where-Object {$_.UserId -eq $User.Id} | `
        Sort-Object {$_.CreatedDateTIme -as [datetime]} 
    
    If ($UserAuditRecords) {
        $MFAFlag = $false
        If ("multifactorauthentication" -in $UserAuditRecords.AuthenticationRequirement) {
            # Identify MFA usage and capture relevant details
            $MFAUsers++
            $Authentication = "MFA"
            ForEach ($Record in $UserAuditRecords) {
                $Status = $Record.Status.AdditionalDetails
                $MFARecordDateTime = $Record.CreatedDateTIme 
                If ($Status -eq 'MFA completed in Azure AD') {
                    # Capture details when MFA is performed
                    $MFAStatus = "MFA Performed"
                    $MFAMethodsUsed = $Record.AuthenticationDetails.AuthenticationMethod -join ", "
                    $MFAFlag = $true
                } ElseIf ($MFAFlag -eq $false) {
                    # Capture details when an existing claim is used
                    $MFAStatus = "Existing claim in the token used"
                    $MFAMethodsUsed = 'Existing claim'                  
                }
            }
        } Else {
            # If no MFA sign-in records exist, the user uses single-factor authentication
            $Authentication = "Single factor"
        }
    }
    $UserLastSignInDate = $User.SignInActivity.LastSignInDateTime
    $ReportLine = [PSCustomObject][Ordered]@{ 
        User            = $User.Id
        Name            = $User.DisplayName
        UPN             = $User.UserPrincipalName
        LastSignIn      = $UserLastSignInDate
        Authentication  = $Authentication
        'MFA timestamp' = $MFARecordDateTime
        'MFA status'    = $MFAStatus
        'MFA methods'   = $MFAMethodsUsed
    }
    $Report.Add($ReportLine)
}

# Output the report to a grid view and CSV file
$Report | Out-GridView
$Report | Export-CSV -NoTypeInformation -Path $CSVOutputFile

[float]$MFACheck = ($MFAUsers/$Users.Count)*100
$PercentMFAUsers = ($MFAUsers/$Users.Count).ToString('P')

Write-Host ("{0} out of {1} users have used MFA." -f $MFAUsers, $Users.Count)
If ($MFACheck -gt 38) {
    Write-Host ("Great job! Tenant MFA usage percentage is {0}, which is above the Entra ID norm of 38%." -f $PercentMFAUsers)
} Else {
    Write-Host ("Attention needed! Tenant MFA usage percentage is {0}, which is below the Entra ID norm of 38%." -f $PercentMFAUsers)
}
