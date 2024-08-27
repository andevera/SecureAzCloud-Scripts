<#
.SYNOPSIS
    This script decodes PowerShell commands executed by a running process on a Windows system.

.DESCRIPTION
    The Decode-PowerShellCommandFromProcess script identifies and decodes PowerShell commands that are running on a system.
    It leverages PowerShell's ability to access and analyze process memory to retrieve and decode encoded commands.
    The script can be useful for security analysis, incident response, and forensic investigations.

.PARAMETER ProcessName
    The name of the process to analyze (e.g., 'powershell', 'pwsh').

.PARAMETER ProcessId
    The ID of the process to analyze. If not specified, all instances of the process specified by ProcessName will be analyzed.

.PARAMETER OutCSV
    The path to a CSV file where the decoded commands will be saved.

.PARAMETER GridView
    If specified, the decoded commands will be displayed in a GridView.

.EXAMPLE
    .\Decode-PowerShellCommandFromProcess.ps1 -ProcessName "powershell" -OutCSV "C:\DecodedCommands.csv"
    This example decodes PowerShell commands from all running instances of 'powershell' and saves them to a CSV file.

.EXAMPLE
    .\Decode-PowerShellCommandFromProcess.ps1 -ProcessId 1234 -GridView
    This example decodes PowerShell commands from the process with ID 1234 and displays them in a GridView.

.NOTES
    Author: Ankit Gupta
    Version: 1.0 - 25-Aug-2024
    GitHub Link: https://github.com/AnkitG365/SecureAzCloud-Scripts

    This script should be tested in a non-production environment before being used in production.

#>

param (
    [Parameter(Mandatory = $true, HelpMessage = "Name of the process to analyze (e.g., 'powershell', 'pwsh')")]
    [string]$ProcessName,

    [Parameter(Mandatory = $false, HelpMessage = "Process ID to analyze. If not specified, all instances of the process will be analyzed.")]
    [int]$ProcessId,

    [Parameter(Mandatory = $false, HelpMessage = "Path to save the decoded commands to a CSV file")]
    [string]$OutCSV,

    [Parameter(Mandatory = $false, HelpMessage = "Display decoded commands in a GridView")]
    [switch]$GridView
)

function Get-ProcessCommandLine {
    param (
        [Parameter(Mandatory = $true)][int]$PID
    )

    $query = "SELECT CommandLine FROM Win32_Process WHERE ProcessId = $PID"
    $process = Get-WmiObject -Query $query

    return $process.CommandLine
}

function Decode-Command {
    param (
        [Parameter(Mandatory = $true)][string]$EncodedCommand
    )

    try {
        $decodedBytes = [System.Convert]::FromBase64String($EncodedCommand)
        $decodedCommand = [System.Text.Encoding]::Unicode.GetString($decodedBytes)
        return $decodedCommand
    }
    catch {
        Write-Warning "Failed to decode command: $EncodedCommand"
        return $null
    }
}

function Analyze-Process {
    param (
        [Parameter(Mandatory = $true)][System.Diagnostics.Process]$Process
    )

    Write-Host "Analyzing process: $($Process.ProcessName) (ID: $($Process.Id))" -ForegroundColor Cyan

    $commandLine = Get-ProcessCommandLine -PID $Process.Id

    if ($commandLine -match "-EncodedCommand ([A-Za-z0-9+/=]+)") {
        $encodedCommand = $matches[1]
        $decodedCommand = Decode-Command -EncodedCommand $encodedCommand

        if ($decodedCommand) {
            [PSCustomObject]@{
                ProcessName   = $Process.ProcessName
                ProcessId     = $Process.Id
                EncodedCommand = $encodedCommand
                DecodedCommand = $decodedCommand
            }
        }
    }
    else {
        Write-Host "No encoded command found for process: $($Process.ProcessName) (ID: $($Process.Id))" -ForegroundColor Yellow
        return $null
    }
}

# Main script logic
$decodedCommands = @()

if ($ProcessId) {
    $process = Get-Process -Id $ProcessId -ErrorAction SilentlyContinue
    if ($process) {
        $decodedCommands += Analyze-Process -Process $process
    }
    else {
        Write-Warning "Process with ID $ProcessId not found."
    }
}
else {
    $processes = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
    if ($processes) {
        foreach ($process in $processes) {
            $decodedCommands += Analyze-Process -Process $process
        }
    }
    else {
        Write-Warning "No processes found with name: $ProcessName."
    }
}

# Output results
if ($decodedCommands.Count -gt 0) {
    if ($GridView) {
        $decodedCommands | Out-GridView -Title "Decoded PowerShell Commands"
    }

    if ($OutCSV) {
        try {
            $decodedCommands | Export-Csv -Path $OutCSV -NoTypeInformation -Force
            Write-Host "Decoded commands exported to $OutCSV" -ForegroundColor Green
        }
        catch {
            Write-Warning "Failed to export decoded commands to $OutCSV. Check the file path and permissions."
        }
    }

    if (-not $GridView -and -not $OutCSV) {
        $decodedCommands | Format-Table -AutoSize
    }
}
else {
    Write-Warning "No encoded PowerShell commands found for the specified process(es)."
}
