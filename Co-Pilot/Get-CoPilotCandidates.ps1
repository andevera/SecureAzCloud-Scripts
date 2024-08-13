<#
    .SYNOPSIS
        Script to analyze user activity and determine eligibility for Copilot for Microsoft 365 licenses.

    .DESCRIPTION
        This script connects to Microsoft Graph and retrieves usage data for Teams, Exchange, and OneDrive. 
        It evaluates user activity based on specific criteria and generates a report indicating which users 
        are recommended for Copilot licenses.

    .NOTES
        Author: Ankit Gupta
        Last Modified: 2024-08-12
        Version: 1.1

    .EXAMPLE
        .\Find-CopilotAuditRecords.PS1

        This example retrieves user activity data and assesses eligibility for Copilot licenses.
#>

# Connect to Microsoft Graph with necessary permissions
Connect-MgGraph -NoWelcome -Scopes Reports.Read.All, ReportSettings.ReadWrite.All, User.Read.All

$TempDownloadFile = "c:\temp\y.csv" # Changed file name for temporary storage
$ObscureFlag = $false
$CSVOutputFile = "C:\temp\CopilotUserEligibility.CSV" # Updated output file name

$Uri = "https://graph.microsoft.com/beta/admin/reportSettings"

# Check if tenant data concealment is enabled for reports, and disable it temporarily
$DisplaySettings = Invoke-MgGraphRequest -Method Get -Uri $Uri
If ($DisplaySettings['displayConcealedNames'] -eq $true) { 
   $ObscureFlag = $true
   Write-Host "Temporarily disabling data concealment for reports..." -ForegroundColor Yellow
   Invoke-MgGraphRequest -Method PATCH -Uri $Uri -Body (@{"displayConcealedNames"= $false} | ConvertTo-Json) 
}

# Identify user accounts eligible for Copilot based on their licenses
Write-Host "Identifying eligible user accounts based on assigned licenses..."
[array]$Users = Get-MgUser -Filter "assignedLicenses/any(s:s/skuId eq 6fd2c87f-b296-42f0-b197-1e91e994b910) `
    or assignedLicenses/any(s:s/skuid eq c7df2760-2c81-4ef7-b578-5b5392b571df) `
    or assignedLicenses/any(s:s/skuid eq 05e9a617-0261-4cee-bb44-138d3ef5d965) `
    or assignedLicenses/any(s:s/skuid eq 06ebc4ee-1bb5-47dd-8120-11324bc54e08)" `
    -ConsistencyLevel Eventual -CountVariable Licenses -All -Sort 'displayName' `
    -Property Id, displayName, signInActivity, userPrincipalName -PageSize 990 # Reduced page size for testing purposes

Write-Host "Fetching user activity data from Teams, Exchange, and OneDrive for the last 30 days..."
# Retrieve Teams user activity data
$Uri = "https://graph.microsoft.com/v1.0/reports/getTeamsUserActivityUserDetail(period='D30')"
Invoke-MgGraphRequest -Uri $Uri -Method GET -OutputFilePath $TempDownloadFile
[array]$TeamsUserData = Import-CSV $TempDownloadFile

# Retrieve Email activity data
$Uri = "https://graph.microsoft.com/v1.0/reports/getEmailActivityUserDetail(period='D30')"
Invoke-MgGraphRequest -Uri $Uri -Method GET -OutputFilePath $TempDownloadFile
[array]$EmailUserData = Import-CSV $TempDownloadFile

# Retrieve OneDrive data 
$Uri = "https://graph.microsoft.com/v1.0/reports/getOneDriveActivityUserDetail(period='D30')"
Invoke-MgGraphRequest -Uri $Uri -Method GET -OutputFilePath $TempDownloadFile
[array]$OneDriveUserData = Import-CSV $TempDownloadFile

# Retrieve Apps usage detail
$Uri = "https://graph.microsoft.com/v1.0/reports/getM365AppUserDetail(period='D30')"
Invoke-MgGraphRequest -Uri $Uri -Method GET -OutputFilePath $TempDownloadFile
[array]$AppsUserData = Import-CSV $TempDownloadFile

Write-Host "Analyzing user activity to determine Copilot eligibility..."
$CopilotReport = [System.Collections.Generic.List[Object]]::new()
ForEach ($User in $Users) {
    Write-Host ("Analyzing activity for {0}..." -f $User.displayName)
    $UserTeamsData = $TeamsUserData | Where-Object 'User Principal Name' -match $User.UserPrincipalName
    $UserOneDriveData = $OneDriveUserData | Where-Object 'User Principal Name' -match $User.UserPrincipalName
    $UserEmailData = $EmailUserData | Where-Object 'User Principal Name' -match $User.UserPrincipalName
    $UserAppsData = $AppsUserData | Where-Object 'User Principal Name' -match $User.UserPrincipalName

    $LastSignInDate = $null
    $DaysSinceLastSignIn = $null
    If ($User.signInActivity.LastSignInDateTime) {
        $LastSignInDate = Get-Date $User.signInActivity.LastSignInDateTime -format 'dd-MMM-yyyy'
        $DaysSinceLastSignIn = (New-TimeSpan $User.signInActivity.LastSignInDateTime).Days
    }
    [int]$Fails = 0; [int]$Points = 0
    # Test 1 - User signed in within the last 15 days
    If ($DaysSinceLastSignIn -le 15) {
        $Test1 = "Pass"
        $Points = 30 # Increased points for test 1
    } Else {
        $Test1 = "Fail"
        $Fails++
    }
    # Test 2 - Minimum Teams activity criteria
    If (([int]$UserTeamsData.'Team Chat Message Count' -ge 30) -and ([int]$UserTeamsData.'Meetings Attended Count' -ge 8)) { # Increased thresholds
        $Test2 = "Pass"
        $Points = $Points + 25 # Increased points for test 2
    } Else {
        $Test2 = "Fail"
        $Fails++
    }
    # Test 3 - Email activity criteria
    If (([int]$UserEmailData.'Send Count' -ge 80) -and ([int]$UserEmailData.'Receive Count' -ge 150)) { # Increased thresholds
        $Test3 = "Pass" 
        $Points = $Points + 20
    } Else {
        $Test3 = "Fail"
        $Fails++
    }
    # Test 4 - OneDrive activity criteria
    If ([int]$UserOneDriveData.'Viewed Or Edited File Count' -ge 15) { # Increased threshold
        $Test4 = "Pass"
        $Points = $Points + 20
    } Else {
        $Test4 = "Fail"
        $Fails++
    }
    # Test 5 - Apps usage criteria
    If ($UserAppsData.Outlook -eq "Yes" -and $UserAppsData.Word -eq "Yes" -and $UserAppsData.Excel -eq "Yes") {
        $Test5 = "Pass"
        $Points = $Points + 20 # Increased points for test 5
    } Else {
        $Test5 = "Fail"
        $Fails++
    }

    If ($Points -ge 95) { # Adjusted the threshold for Copilot approval
        $CopilotApproved = "Approved"
    } Else {
        $CopilotApproved = "Not eligible"
    }

    $ReportLine = [PSCustomObject][Ordered]@{ 
        User                = $User.displayName
        UPN                 = $User.UserPrincipalName
        'Last Signin'       = $LastSignInDate
        'Days since signin' = $DaysSinceLastSignIn
        Points              = $Points
        'Test 1: Sign in'   = $Test1
        'Test 2: Teams'     = $Test2
        'Test 3: Email'     = $Test3
        'Test 4: OneDrive'  = $Test4
        'Test 5: Apps'      = $Test5
        'Copilot approved'  = $CopilotApproved
    }
    $CopilotReport.Add($ReportLine)
}

[array]$CopilotRecommendations = $CopilotReport | Where-Object {$_.'Copilot approved' -eq 'Approved'} | Select-Object User, UPN
$CopilotReport | Export-CSV -NoTypeInformation $CSVOutputFile
Clear-Host
Write-Host ""
Write-Host ("Based on analysis of user activity and apps, {0} users are recommended" -f $CopilotRecommendations.Count)
Write-Host ("for Copilot for Microsoft 365 licenses. Details can be found in: {0}" -f $CSVOutputFile)
Write-Host ""
$CopilotRecommendations

# Reset the tenant report obscure data setting if it was changed earlier
If ($ObscureFlag -eq $True) {
    Write-Host "Restoring tenant data concealment setting..." -ForegroundColor Yellow
    Invoke-MgGraphRequest -Method PATCH -Uri 'https://graph.microsoft.com/beta/admin/reportSettings' `
     -Body (@{"displayConcealedNames"= $true} | ConvertTo-Json) 
}

# Please test the script in a safe environment before using it in production. Adjust thresholds and points based on your organization's needs. This script has been created first time with help of GithubCopilot and may contain errors. Feel free to reach out.
