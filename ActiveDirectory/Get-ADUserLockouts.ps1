<#
.SYNOPSIS
    This script retrieves and processes account lockout events from the Primary Domain Controller (PDC) to help diagnose user lockouts in Active Directory.

.DESCRIPTION
    The script connects to the PDC Emulator, queries the Security event log for account lockout events (Event ID 4740), and processes the data to extract relevant details such as the locked-out user and the computer that triggered the lockout.

.EXAMPLE
    .\Get-ADUserLockouts.ps1
    This example retrieves all account lockout events from the PDC and displays relevant information about each lockout.

.NOTES
    Author: Ankit Gupta
    GitHub: https://github.com/AnkitG365/SecureAzCloud-Scripts
    Version: 1.0 - 12-Aug-2024

    Always test scripts in a controlled environment before deploying them in production.
#>

# Ensure the Active Directory module is loaded
Import-Module ActiveDirectory

# Set up parameters for monitoring account lockouts
$AccountLockoutEventID = 4740

# Identify the Primary Domain Controller (PDC) Emulator in your domain
$PrimaryDomainController = (Get-ADDomain).PDCEmulator

# Connect to the PDC Emulator
Enter-PSSession -ComputerName $PrimaryDomainController

# Query the Security event log on the PDC for account lockout events
$LockoutEvents = Get-WinEvent -ComputerName $PrimaryDomainController -FilterHashtable @{
    LogName = 'Security'
    ID      = $AccountLockoutEventID
}

# Display the first event's message for reference
$LockoutEvents[0].Message

# Use regex to extract the 'Caller Computer Name' from the event message
$LockoutEvents[0].Message -match 'Caller Computer Name:\s+(?<ComputerName>[^\s]+)'
$Matches['ComputerName']

# Access and display properties of the event directly
$LockoutEvents[0].Properties
$LockoutEvents[0].Properties[1].Value

# Process each lockout event and create a custom object with relevant details
$LockoutDetails = ForEach ($Event in $LockoutEvents) {
    [PSCustomObject]@{
        UserName       = $Event.Properties[0].Value
        CallerComputer = $Event.Properties[1].Value
        TimeStamp      = $Event.TimeCreated
    }
}

# Convert the above code into a reusable function to monitor user lockouts
function Get-UserLockoutEvents {
    [CmdletBinding()]
    param (
        [string]$Username = "*"
    )

    begin {
        $AccountLockoutEventID = 4740
        $PrimaryDomainController = (Get-ADDomain).PDCEmulator
    }

    process {
        $LockoutEvents = Get-WinEvent -ComputerName $PrimaryDomainController -FilterHashtable @{
            LogName = 'Security'
            ID      = $AccountLockoutEventID
        } | Where-Object { $_.Properties[0].Value -like $Username }

        ForEach ($Event in $LockoutEvents) {
            [PSCustomObject]@{
                UserName       = $Event.Properties[0].Value
                CallerComputer = $Event.Properties[1].Value
                TimeStamp      = $Event.TimeCreated
            }
        }
    }
}

# Example usage: Get lockout events for a specific user or all users
Get-UserLockoutEvents -Username "john.doe"

# General usage to retrieve all user lockout events
Get-UserLockoutEvents
