<#
=============================================================================================
Name:           Audit-TeamsMeetingsAndAttendance.ps1
Description:    This script exports Teams meeting reports and attendance reports into two CSV files.
Author:         Ankit Gupta
GitHub:         https://github.com/AnkitG365/SecureAzCloud-Scripts
=============================================================================================
#>

Param
(
    [Parameter(Mandatory = $false)]
    [Nullable[DateTime]]$StartDate,
    [Nullable[DateTime]]$EndDate,
    [switch]$NoMFA,
    [string]$UserName,
    [string]$Password
)

Function Connect-Modules
{
    # Ensure the Exchange Online Management module is installed
    if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
        Write-Host "Exchange Online PowerShell module not found." -ForegroundColor Yellow
        $confirm = Read-Host "Do you want to install the module? [Y] Yes [N] No"
        if ($confirm -match "[yY]") {
            Write-Host "Installing Exchange Online PowerShell module..."
            Install-Module -Name ExchangeOnlineManagement -Repository PSGallery -AllowClobber -Force
        } else {
            Write-Host "Exchange Online module is required to connect. Please install it using Install-Module ExchangeOnlineManagement."
            Exit
        }
    }

    # Ensure the AzureAD module is installed
    if (-not (Get-Module -ListAvailable -Name AzureAD)) {
        Write-Host "Azure AD module not found." -ForegroundColor Yellow
        $confirm = Read-Host "Do you want to install the Azure AD module? [Y] Yes [N] No"
        if ($confirm -match "[yY]") {
            Write-Host "Installing Azure AD PowerShell module..."
            Install-Module -Name AzureAD -Repository PSGallery -AllowClobber -Force
        } else {
            Write-Host "Azure AD module is required to generate the report. Please install it using Install-Module AzureAD."
            Exit
        }
    }

    # Connect to Exchange Online and Azure AD
    if ($NoMFA.IsPresent) {
        if ($UserName -and $Password) {
            $SecuredPassword = ConvertTo-SecureString -AsPlainText $Password -Force
            $Credential = New-Object System.Management.Automation.PSCredential ($UserName, $SecuredPassword)
        } else {
            $Credential = Get-Credential
        }
        Write-Host "Connecting to Azure AD..."
        Connect-AzureAD -Credential $Credential | Out-Null
        Write-Host "Connecting to Exchange Online..."
        Connect-ExchangeOnline -Credential $Credential
    } else {
        Write-Host "Connecting to Exchange Online..."
        Connect-ExchangeOnline
        Write-Host "Connecting to Azure AD..."
        Connect-AzureAD | Out-Null
    }
}

Function Get-TeamMeetings
{
    $Results = @()
    $Count = 0
    Write-Host "Retrieving Teams meetings data..."
    Search-UnifiedAuditLog -StartDate $StartDate -EndDate $EndDate -Operations "MeetingDetail" -ResultSize 5000 | ForEach-Object {
        $Count++
        Write-Progress -Activity "Processing Teams meetings" -Status "Processed $Count meetings..."
        $AuditData = $_.AuditData | ConvertFrom-Json
        $Result = [PSCustomObject]@{
            'Meeting ID'     = $AuditData.ID
            'Created By'     = $AuditData.UserId
            'Start Time'     = (Get-Date $AuditData.StartTime).ToLocalTime()
            'End Time'       = (Get-Date $AuditData.EndTime).ToLocalTime()
            'Meeting Type'   = $AuditData.ItemName
            'Meeting Link'   = $AuditData.MeetingURL
            'More Info'      = $AuditData
        }
        $Results += $Result
    }
    $Results | Export-Csv -Path $ExportCSV -NoTypeInformation -Force
    Write-Host "$Count meetings details have been exported." -ForegroundColor Green
}

$MaxStartDate = (Get-Date).AddDays(-89).Date

# Set default date range if not provided
if (-not $StartDate) { $StartDate = $MaxStartDate }
if (-not $EndDate) { $EndDate = Get-Date }

# Validate the date range
if ($StartDate -lt $MaxStartDate) {
    Write-Host "Audit can only be retrieved for the past 90 days. Please select a date after $MaxStartDate." -ForegroundColor Red
    Exit
}

if ($EndDate -lt $StartDate) {
    Write-Host "End date should be later than start date." -ForegroundColor Red
    Exit
}

$ExportCSV = ".\TeamsMeetingsReport_$((Get-Date -format yyyy-MMM-dd_HH-mm)).csv"
$OutputCSV = ".\TeamsMeetingAttendanceReport_$((Get-Date -format yyyy-MMM-dd_HH-mm)).csv"
$IntervalTimeInMinutes = 1440
$CurrentStart = $StartDate
$CurrentEnd = $CurrentStart.AddMinutes($IntervalTimeInMinutes)

# Adjust end date if it exceeds the specified end date
if ($CurrentEnd -gt $EndDate) { $CurrentEnd = $EndDate }

# Ensure valid date range
if ($CurrentStart -eq $CurrentEnd) {
    Write-Host "Start and end times are the same. Please enter a different time range." -ForegroundColor Red
    Exit
}

Connect-Modules
Get-TeamMeetings

Write-Host "Generating Teams meeting attendance report..."
$ProcessedAuditCount = 0
$OutputEvents = 0
$RetriveOperation = "MeetingParticipantDetail"

while ($true) {
    $Results = Search-UnifiedAuditLog -StartDate $CurrentStart -EndDate $CurrentEnd -Operations $RetriveOperation -ResultSize 5000
    $ResultCount = $Results.Count
    $ProcessedAuditCount += $ResultCount

    foreach ($Result in $Results) {
        $AuditData = $Result.AuditData | ConvertFrom-Json
        $ExportResult = [PSCustomObject]@{
            'Meeting ID'      = $AuditData.MeetingDetailId
            'Created By'      = $Result.UserIDs
            'Attendees'       = if ($AuditData.Attendees.RecipientType -ne "User") { $AuditData.Attendees.DisplayName } else { (Get-AzureADUser -ObjectId $AuditData.Attendees.userObjectId).UserPrincipalName }
            'Attendee Type'   = $AuditData.Attendees.RecipientType
            'Joined Time'     = (Get-Date $AuditData.JoinTime).ToLocalTime()
            'Left Time'       = (Get-Date $AuditData.LeaveTime).ToLocalTime()
            'More Info'       = $AuditData
        }
        $ExportResult | Export-Csv -Path $OutputCSV -NoTypeInformation -Append
        $OutputEvents++
    }

    if ($ProcessedAuditCount -ge 50000) {
        Write-Host "Reached maximum records for current range. Consider reducing the time interval." -ForegroundColor Red
        $Confirm = Read-Host "Do you want to continue? [Y] Yes [N] No"
        if ($Confirm -match "[yY]") {
            Write-Host "Proceeding with possible data loss..."
            $CurrentStart = $CurrentEnd
            $CurrentEnd = $CurrentStart.AddMinutes($IntervalTimeInMinutes)
        } else {
            Write-Host "Please rerun the script with a reduced time interval." -ForegroundColor Red
            Exit
        }
    }

    if ($ResultCount -lt 5000 -or $CurrentEnd -ge $EndDate) { break }

    $CurrentStart = $CurrentEnd
    $CurrentEnd = $CurrentStart.AddMinutes($IntervalTimeInMinutes)
    if ($CurrentEnd -gt $EndDate) { $CurrentEnd = $EndDate }
}

# Open output file after execution
if ($OutputEvents -eq 0) {
    Write-Host "No records found."
} else {
    Write-Host "`nThe Teams meeting attendance report contains $OutputEvents audit records." -ForegroundColor Green
    if (Test-Path $OutputCSV) {
        Write-Host "`nThe Teams meetings attendance report is available at: $OutputCSV" -ForegroundColor Yellow
        $Prompt = New-Object -ComObject wscript.shell
        $UserInput = $Prompt.popup("Do you want to open the output file?", 0, "Open Output File", 4)
        if ($UserInput -eq 6) {
            Invoke-Item $OutputCSV
            Invoke-Item $ExportCSV
        }
    }
}

# Disconnect from Exchange Online
Disconnect-ExchangeOnline -Confirm:$false -InformationAction Ignore -ErrorAction SilentlyContinue
