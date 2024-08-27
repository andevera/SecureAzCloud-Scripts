<#
.SYNOPSIS
    This script provides a detailed overview of the system's status, including CPU, memory, disk usage, network information, and more. It also reports on services, event logs, installed software, and pending updates.

.DESCRIPTION
    The Get-SystemOverview script is designed to gather and display critical system information in a formatted output. It includes CPU, memory, and disk details, network adapter status, top CPU-consuming processes, event logs, services status, and more. This script is intended for IT professionals to quickly assess the health and status of a system.

.PARAMETER None
    No parameters are required for this script.

.EXAMPLE
    .\Get-SystemOverview.PS1
    This example runs the script to display a comprehensive system overview.

.NOTES
    Author: Ankit Gupta
    Version: 1.0 - 25-Aug-2024
    GitHub Link: https://github.com/AnkitG365/SecureAzCloud-Scripts

    This script should be tested in a non-production environment before being used in production.

#>

# Function to gather and display system uptime
function Get-SystemUptime {
    $Uptime = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
    $FormattedUptime = (Get-Date) - $Uptime
    Write-Host "System Uptime:`t`t`t$($FormattedUptime.Days) days, $($FormattedUptime.Hours) hours, $($FormattedUptime.Minutes) minutes" -ForegroundColor Cyan
}

# Function to gather and display system information
function Get-SystemInformation {
    $OS = Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object Caption, Version
    $CPU = $((Get-CimInstance -ClassName Win32_Processor).name)
    $Disks = foreach ($disk in Get-CimInstance -Class win32_logicaldisk) {
        [PSCustomObject]@{
            Drive = $disk.DeviceID
            Total = [math]::Round($disk.Size / 1GB, 2)
            Free  = [math]::Round($disk.FreeSpace / 1GB, 2)
        }
    }
    $Memory = "$(Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property capacity -Sum | ForEach-Object {"{0:N2}" -f ([math]::round(($_.Sum/1GB),2))})Gb/$([math]::round((Get-CIMInstance Win32_OperatingSystem).FreePhysicalMemory / 1024 / 1024, 2))Gb"
    $Processes = (Get-Process).count
    $NetworkAdapters = foreach ($adapter in Get-NetAdapter | Where-Object Status -eq Up | Sort-Object Name, Type) {
        foreach ($ipinterface in Get-NetIPAddress | Where-Object InterfaceAlias -eq $adapter.Name) {
            [PSCustomObject]@{
                Adapter = $adapter.name
                Type    = $ipinterface.AddressFamily
                Address = $ipinterface.IPAddress
            }
        }
    }
    $UsersLoggedIn = (Get-CimInstance -Query "select * from win32_process where name='explorer.exe'").ProcessID.count
    $SystemLoad = (Get-Counter "\Processor(_Total)\% Processor Time").CounterSamples.CookedValue
    $SwapUsage = (Get-Counter "\Paging File(_Total)\% Usage").CounterSamples.CookedValue

    Write-Host "Welcome to the $($host.Name) of $($env:COMPUTERNAME) ($($OS.Caption) $($OS.Version))`n" -ForegroundColor Green
    Write-Host "System information as of $(Get-Date -Format 'dd-MM-yyyy HH:MM')`n" -ForegroundColor Green
    Write-Host "CPU:`t`t`t`t$($CPU)" -ForegroundColor Green
    Write-Host "System load:`t`t`t$("{0:N2}%" -f $SystemLoad)" -ForegroundColor Green
    foreach ($disk in $Disks) {
        Write-Host "Disk $($disk.Drive) Total/Free:`t`t$($disk.Total)/$($disk.Free)" -ForegroundColor Green
    }
    Write-Host "Memory usage (Total/Free):`t$($Memory)" -ForegroundColor Green
    Write-Host "Swap usage:`t`t`t$("{0:N2}%" -f $SwapUsage)" -ForegroundColor Green
    Write-Host "Processes:`t`t`t$($Processes)" -ForegroundColor Green
    Write-Host "Users logged in:`t`t$($UsersLoggedIn)" -ForegroundColor Green
    foreach ($adapter in $NetworkAdapters | Sort-Object Adapter, Type) {
        Write-Host "Adapter $($adapter.Adapter):`t`t$($adapter.Type) - $($adapter.Address)" -ForegroundColor Green
    }
}

# Function to gather and display event log errors and warnings
function Get-EventLogSummary {
    $EventLogSummary = Get-EventLog -LogName System -EntryType Error, Warning -Newest 10
    Write-Host "`nRecent Event Log Errors and Warnings:`n" -ForegroundColor Cyan
    $EventLogSummary | Format-Table TimeGenerated, EntryType, Source, EventID, Message -AutoSize
}

# Function to gather and display network adapter details
function Get-NetworkAdapterDetails {
    $NetworkAdapterDetails = Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object Name, Status, LinkSpeed
    Write-Host "`nNetwork Adapter Details:`n" -ForegroundColor Cyan
    $NetworkAdapterDetails | Format-Table Name, Status, LinkSpeed -AutoSize
}

# Function to gather and display top CPU-consuming processes
function Get-TopCPUProcesses {
    $TopCPUProcesses = Get-Process | Sort-Object CPU -Descending | Select-Object -First 5 Name, CPU
    Write-Host "`nTop 5 CPU Consuming Processes:`n" -ForegroundColor Cyan
    $TopCPUProcesses | Format-Table Name, CPU -AutoSize
}

# Function to gather and display service status summary
function Get-ServiceStatus {
    $ImportantServices = "wuauserv", "BITS", "WinDefend"
    $ServiceStatus = Get-Service -Name $ImportantServices
    Write-Host "`nService Status Summary:`n" -ForegroundColor Cyan
    $ServiceStatus | Format-Table Name, Status, StartType -AutoSize
}

# Function to gather and display pending Windows updates
function Get-PendingUpdates {
    $PendingUpdates = (New-Object -ComObject Microsoft.Update.Session).CreateUpdateSearcher().Search("IsInstalled=0").Updates
    Write-Host "`nPending Windows Updates:`n" -ForegroundColor Cyan
    $PendingUpdates | Select-Object Title, IsMandatory | Format-Table Title, IsMandatory -AutoSize
}

# Function to gather and display disk health information
function Get-DiskHealth {
    $DiskHealth = Get-WmiObject -Namespace root\wmi -Class MSStorageDriver_FailurePredictStatus
    Write-Host "`nDisk Health Information:`n" -ForegroundColor Cyan
    $DiskHealth | Format-Table InstanceName, PredictFailure -AutoSize
}

# Function to gather and display Windows Firewall status
function Get-FirewallStatus {
    $FirewallStatus = Get-NetFirewallProfile -All | Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction
    Write-Host "`nWindows Firewall Status:`n" -ForegroundColor Cyan
    $FirewallStatus | Format-Table Name, Enabled, DefaultInboundAction, DefaultOutboundAction -AutoSize
}


# Gather and display all system information
Get-SystemUptime
Get-SystemInformation
Get-EventLogSummary
Get-NetworkAdapterDetails
Get-TopCPUProcesses
Get-ServiceStatus
Get-PendingUpdates
Get-DiskHealth
Get-FirewallStatus
