<#
.SYNOPSIS
    This script searches through event logs on a local or remote computer for specific events within a given time frame.

.DESCRIPTION
    The Search-EventLogs script allows you to filter and retrieve events from specified event logs on a computer. You can filter by event ID, time frame, and even search for specific text within the event messages. The script supports outputting results to a CSV file, displaying them in a GridView, or showing them directly in the console.

.PARAMETER ComputerName
    The name of the remote computer to search event logs on. Defaults to the local computer.

.PARAMETER Hours
    The number of hours to search back from the current time.

.PARAMETER EventID
    The specific event ID(s) to search for.

.PARAMETER EventLogName
    The name(s) of the event logs to search in. If not specified, all event logs will be searched.

.PARAMETER Gridview
    If specified, the results will be displayed in an Out-GridView window.

.PARAMETER Filter
    A string to search for within the event message.

.PARAMETER OutCSV
    The file path to export the results to a CSV file.

.PARAMETER ExcludeLog
    A list of event logs to exclude from the search.

.EXAMPLE
    .\Search-EventLogs.ps1 -ComputerName 'Server01' -Hours 24 -EventID 4625 -OutCSV "C:\logs\FailedLogons.csv"
    This example retrieves all failed logon events (Event ID 4625) from the last 24 hours on Server01 and exports the results to a CSV file.

.NOTES
    Author: Ankit Gupta
    Version: 1.0 - 25-Aug-2024
    GitHub Link: https://github.com/AnkitG365/SecureAzCloud-Scripts

    This script should be tested in a non-production environment before being used in production.
#>

function Get-FilteredEventLogs {
    [CmdletBinding(DefaultParameterSetName = 'All')]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Name of remote computer")]
        [string]$TargetComputer = $env:COMPUTERNAME,

        [Parameter(Mandatory = $false, HelpMessage = "Number of hours to search back for")]
        [double]$LookBackHours = 1,

        [Parameter(Mandatory = $false, HelpMessage = "Event ID(s) to filter")]
        [int[]]$EventIDFilter,

        [Parameter(Mandatory = $false, HelpMessage = "The name of the event log(s) to search in")]
        [string[]]$LogNameFilter,

        [Parameter(Mandatory = $false, HelpMessage = "Output results in a GridView", ParameterSetName = "GridView")]
        [switch]$ShowInGridView,

        [Parameter(Mandatory = $false, HelpMessage = "String to search for in event messages")]
        [string]$MessageFilter,

        [Parameter(Mandatory = $false, HelpMessage = "Path to save the output CSV", ParameterSetName = "CSV")]
        [string]$CSVOutputPath,

        [Parameter(Mandatory = $false, HelpMessage = "Exclude specific logs from the search")]
        [string[]]$ExcludeLogs
    )

    # Convert $LookBackHours to equivalent date value
    [DateTime]$LookBackTime = (Get-Date).AddHours(-$LookBackHours)

    # Validate and retrieve event logs to search
    if ($LogNameFilter) {
        try {
            $AvailableLogs = Get-WinEvent -ListLog $LogNameFilter -ErrorAction Stop | Where-Object LogName -NotIn $ExcludeLogs
            Write-Host ("Validated specified event logs on {0}, continuing..." -f $TargetComputer) -ForegroundColor Cyan
        }
        catch {
            Write-Warning ("Invalid event log specified or unable to access logs on {0}. Exiting..." -f $TargetComputer)
            return
        }
    } else {
        try {
            $AvailableLogs = Get-WinEvent -ListLog * -ComputerName $TargetComputer | Where-Object LogName -NotIn $ExcludeLogs
        }
        catch {
            Write-Warning ("Failed to retrieve event logs from {0}. Exiting..." -f $TargetComputer)
            return
        }
    }

    # Search and process event logs
    $EventCounter = 1
    $AllEvents = foreach ($Log in $AvailableLogs) {
        Write-Host ("[{0}/{1}] Searching events in {2} on {3}..." -f $EventCounter, $AvailableLogs.Count, $Log.LogName, $TargetComputer) -ForegroundColor Cyan
        $EventCounter++

        try {
            $EventFilter = @{
                LogName   = $Log.LogName
                StartTime = $LookBackTime
            }
            if ($EventIDFilter) {
                $EventFilter.Add('ID', $EventIDFilter)
            }

            $FilteredEvents = Get-WinEvent -FilterHashtable $EventFilter -ErrorAction Stop

            foreach ($Event in $FilteredEvents) {
                if (-not $MessageFilter -or $Event.Message -match $MessageFilter) {
                    [PSCustomObject]@{
                        Time         = $Event.TimeCreated.ToString('dd-MM-yyyy HH:mm')
                        Computer     = $TargetComputer
                        LogName      = $Event.LogName
                        ProviderName = $Event.ProviderName
                        Level        = $Event.LevelDisplayName
                        User         = if ($Event.UserId) { $Event.UserId.ToString() } else { "N/A" }
                        EventID      = $Event.Id
                        Message      = $Event.Message
                    }
                }
            }
        }
        catch {
            Write-Host ("No events found in {0} within the specified time-frame, event ID, or message filter on {1}. Skipping..." -f $Log.LogName, $TargetComputer) -ForegroundColor Yellow
        }
    }

    # Output results to GridView
    if ($ShowInGridView -and $AllEvents) {
        return $AllEvents | Sort-Object Time, LogName | Out-GridView -Title 'Retrieved events...'
    }

    # Output results to CSV file
    if ($CSVOutputPath -and $AllEvents) {
        try {
            $AllEvents | Sort-Object Time, LogName | Export-Csv -NoTypeInformation -Delimiter ';' -Encoding UTF8 -Path $CSVOutputPath -ErrorAction Stop
            Write-Host ("Results exported to {0}" -f $CSVOutputPath) -ForegroundColor Green
        }
        catch {
            Write-Warning ("Failed to save results to {0}. Check path or permissions. Exiting..." -f $CSVOutputPath)
            return
        }
    }

    # Output results to console if no other output specified
    if (-not $CSVOutputPath -and -not $ShowInGridView -and $AllEvents) {
        return $AllEvents | Sort-Object Time, LogName
    }

    # Return warning if no results were found
    if (-not $AllEvents) {
        Write-Warning ("No results were found on {0}..." -f $TargetComputer)
    }
}
