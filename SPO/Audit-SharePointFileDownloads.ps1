<#
=============================================================================================
Name:           Audit File Downloads in SharePoint Online using PowerShell
Version:        1.0
Author:         Ankit Gupta
GitHub:         https://github.com/AnkitG365/SecureAzCloud-Scripts

#>

Param
(
    [Parameter(Mandatory = $false)]
    [Nullable[DateTime]]$StartDate,
    [Nullable[DateTime]]$EndDate,
    [Int]$RecentlyDownloadedFiles_In_Days,
    [Switch]$SharePointOnlineOnly,
    [Switch]$OneDriveOnly,
    [Switch]$FileDownloadedByExternalUsersOnly,
    [String]$DownloadedBy,
    [String]$Organization,
    [String]$ClientId,
    [String]$CertificateThumbprint,
    [String]$UserName,
    [String]$Password
)

Function Connect-ExchangeOnlineService
{
    # Check for EXO module installation
    $Module = Get-Module ExchangeOnlineManagement -ListAvailable
    if ($Module.count -eq 0) 
    { 
        Write-Host "Exchange Online PowerShell module is not available" -ForegroundColor Yellow  
        $Confirm = Read-Host "Do you want to install the Exchange Online module? [Y] Yes [N] No" 
        if ($Confirm -match "[yY]") 
        { 
            Write-Host "Installing Exchange Online PowerShell module"
            Install-Module ExchangeOnlineManagement -Repository PSGallery -AllowClobber -Force -Scope CurrentUser
            Import-Module ExchangeOnlineManagement
        } 
        else 
        { 
            Write-Host "EXO module is required to connect to Exchange Online. Please install the module using the Install-Module ExchangeOnlineManagement cmdlet." 
            Exit
        }
    } 

    Write-Host "Connecting to Exchange Online..."
    
    # Authentication using non-MFA account or Certificate-based Authentication
    if (($UserName -ne "") -and ($Password -ne ""))
    {
        $SecuredPassword = ConvertTo-SecureString -AsPlainText $Password -Force
        $Credential = New-Object System.Management.Automation.PSCredential $UserName, $SecuredPassword
        Connect-ExchangeOnline -Credential $Credential
    }
    elseif ($Organization -ne "" -and $ClientId -ne "" -and $CertificateThumbprint -ne "")
    {
        Connect-ExchangeOnline -AppId $ClientId -CertificateThumbprint $CertificateThumbprint -Organization $Organization -ShowBanner:$false
    }
    else
    {
        Connect-ExchangeOnline
    }
}

$MaxStartDate = ((Get-Date).AddDays(-179)).Date

if ($RecentlyDownloadedFiles_In_Days -ne "")
{
    $StartDate = ((Get-Date).AddDays(-$RecentlyDownloadedFiles_In_Days)).Date
    $EndDate = (Get-Date).Date
}

# Retrieving audit log for the past 180 days by default
if (($StartDate -eq $null) -and ($EndDate -eq $null))
{
    $EndDate = (Get-Date).Date
    $StartDate = $MaxStartDate
}

# Prompt for start date if not provided
While ($true)
{
    if ($StartDate -eq $null)
    {
        $StartDate = Read-Host "Enter start time for report generation (e.g., 12/15/2023)"
    }
    Try
    {
        $Date = [DateTime]$StartDate
        if ($Date -ge $MaxStartDate)
        { 
            break
        }
        else
        {
            Write-Host "`nAudit can be retrieved only for the past 180 days. Please select a date after $MaxStartDate" -ForegroundColor Red
            return
        }
    }
    Catch
    {
        Write-Host "`nNot a valid date" -ForegroundColor Red
    }
}

# Prompt for end date if not provided
While ($true)
{
    if ($EndDate -eq $null)
    {
        $EndDate = Read-Host "Enter end time for report generation (e.g., 12/15/2023)"
    }
    Try
    {
        $Date = [DateTime]$EndDate
        if ($EndDate -lt $StartDate)
        {
            Write-Host "End time should be later than start time" -ForegroundColor Red
            return
        }
        break
    }
    Catch
    {
        Write-Host "`nNot a valid date" -ForegroundColor Red
    }
}

$Location = Get-Location
$OutputCSV = "$Location\File_Download_Audit_Report$((Get-Date -format yyyy-MMM-dd-ddd` hh-mm` tt).ToString()).csv" 
$IntervalTimeInMinutes = 1440
$CurrentStart = $StartDate
$CurrentEnd = $CurrentStart.AddMinutes($IntervalTimeInMinutes)

# Check whether CurrentEnd exceeds EndDate
if ($CurrentEnd -gt $EndDate)
{
    $CurrentEnd = $EndDate
}

if ($CurrentStart -eq $CurrentEnd)
{
    Write-Host "Start and end time are the same. Please enter a different time range." -ForegroundColor Red
    Exit
}

Connect-ExchangeOnlineService
$AggregateResults = @()
$CurrentResult = @()
$CurrentResultCount = 0
$AggregateResultCount = 0
Write-Host "`nRetrieving file download audit log from $StartDate to $EndDate..." -ForegroundColor Yellow
$i = 0
$ExportResult = ""   
$ExportResults = @()  
$Operations = "FileDownloaded"

if ($FileDownloadedByExternalUsersOnly.IsPresent)
{
    $UserIds = "*#EXT*"
}
elseif ($DownloadedBy -ne "")
{
    $UserIds = $DownloadedBy
}
else
{
    $UserIds = "*"
}

while ($true)
{ 
    # Getting audit data for the given time range
    $Results = Search-UnifiedAuditLog -StartDate $CurrentStart -EndDate $CurrentEnd -Operations $Operations -UserIds $UserIds -SessionId s -SessionCommand ReturnLargeSet -ResultSize 5000
    $ResultCount = ($Results | Measure-Object).count
    $AllAuditData = @()

    foreach ($Result in $Results)
    {
        $i++
        $PrintFlag = $true
        $MoreInfo = $Result.auditdata
        $AuditData = $Result.auditdata | ConvertFrom-Json
        $ActivityTime = (Get-Date($AuditData.CreationTime)).ToLocalTime()
        $UserID = $AuditData.userId
        $AccessedFile = $AuditData.SourceFileName
        $FileExtension = $AuditData.SourceFileExtension
        $SiteURL = $AuditData.SiteURL
        $Workload = $AuditData.Workload

        if ($SharePointOnlineOnly.IsPresent -and ($Workload -ne "SharePoint"))
        {
            $PrintFlag = $false
        }

        if ($OneDriveOnly.IsPresent -and ($Workload -ne "OneDrive"))
        {
            $PrintFlag = $false
        }

        # Export result to CSV
        if ($PrintFlag -eq $true)
        {
            $OutputEvents++
            $ExportResult = @{
                'Downloaded Time' = $ActivityTime
                'Downloaded By'   = $UserID
                'Workload'        = $Workload
                'More Info'       = $MoreInfo
                'Downloaded File' = $AccessedFile
                'Site URL'        = $SiteURL
                'File Extension'  = $FileExtension
            }
            $ExportResults = New-Object PSObject -Property $ExportResult  
            $ExportResults | Select-Object 'Downloaded Time','Downloaded By','Downloaded File','Site URL','File Extension','Workload','More Info' | Export-Csv -Path $OutputCSV -NoTypeInformation -Append 
        }
    }

    Write-Progress -Activity "`nRetrieving file download audit data from $StartDate to $EndDate..." -Status "Processed audit record count: $i"
    $CurrentResultCount = $CurrentResultCount + $ResultCount

    if ($CurrentResultCount -ge 50000)
    {
        Write-Host "Retrieved max record for current range. Proceeding further may cause data loss. Please rerun the script with a reduced time interval." -ForegroundColor Red
        $Confirm = Read-Host "`nAre you sure you want to continue? [Y] Yes [N] No"
        if ($Confirm -match "[Y]")
        {
            Write-Host "Proceeding with audit log collection despite potential data loss."
            $CurrentStart = $CurrentEnd
            $CurrentEnd = $CurrentStart.AddMinutes($IntervalTimeInMinutes)
            $CurrentResultCount = 0
            if ($CurrentEnd -gt $EndDate)
            {
                $CurrentEnd = $EndDate
            }
        }
        else
        {
            Write-Host "Please rerun the script with a reduced time interval." -ForegroundColor Red
            Exit
        }
    }

    if ($ResultCount -lt 5000)
    { 
        if ($CurrentEnd -eq $EndDate)
        {
            break
        }
        $CurrentStart = $CurrentEnd 
        if ($CurrentStart -gt (Get-Date))
        {
            break
        }
        $CurrentEnd = $CurrentStart.AddMinutes($IntervalTimeInMinutes)
        $CurrentResultCount = 0
        if ($CurrentEnd -gt $EndDate)
        {
            $CurrentEnd = $EndDate
        }
    }                                                                                             
    $ResultCount = 0
}

# Open output file after execution
If ($OutputEvents -eq 0)
{
    Write-Host "No records found."
}
else
{
    Write-Host "`nThe exported report contains $OutputEvents audit records."
    if ((Test-Path -Path $OutputCSV) -eq $true) 
    {
        Write-Host "`nThe output file is available at:" -NoNewline -ForegroundColor Yellow
        Write-Host "$OutputCSV" `n 
        $Prompt = New-Object -ComObject wscript.shell   
        $UserInput = $Prompt.popup("Do you want to open the output file?", 0, "Open Output File", 4)   
        If ($UserInput -eq 6)   
        {   
            Invoke-Item "$OutputCSV"   
        } 
    }
}

# Disconnect Exchange Online session
Disconnect-ExchangeOnline -Confirm:$false -InformationAction Ignore -ErrorAction SilentlyContinue

Write-Host "`n~~ Script prepared by Ankit Gupta ~~" -ForegroundColor Green
Write-Host "~~ Check out " -NoNewline -ForegroundColor Green; Write-Host "https://github.com/AnkitG365/SecureAzCloud-Scripts" -ForegroundColor Yellow -NoNewline; Write-Host " for more scripts. ~~" -ForegroundColor Green `n`n
