<#
.SYNOPSIS
    BitLocker Recovery Key Backup Detection Script.

.DESCRIPTION
    This script is designed to identify BitLocker recovery key backup events for the system drive. 
    It retrieves the BitLocker-protected system volume and checks for events associated with the 
    backup of the system drive’s recovery key.

.NOTES
    Author: Ankit Gupta
    GitHub: https://github.com/AnkitG365/SecureAzCloud-Scripts
    LinkedIn: https://www.linkedin.com/in/ankytgupta/

    Version: 1.0
    Created: 12/08/2024

.REQUIREMENTS
    - PowerShell 5.1 or later
    - BitLocker enabled on the system drive

.EXAMPLE 
    .\Detect-BitLockerKeyBackup.ps1
    This example runs the script to detect BitLocker recovery key backup events for the system drive.
#>

try
{
    ### Retrieve the BitLocker protected system volume
    $BlSysVolume = Get-BitLockerVolume -MountPoint $env:SystemDrive -ErrorAction Stop
    $BlRecoveryProtector = $BlSysVolume.KeyProtector | Where-Object { $_.KeyProtectorType -eq 'RecoveryPassword' } -ErrorAction Stop
    $BlProtectorGuid = $BlRecoveryProtector.KeyProtectorId

    ### Find the event associated with the backup of the system drive’s recovery key
    $BlBackupEvent = Get-WinEvent -ProviderName Microsoft-Windows-BitLocker-API -FilterXPath "*[System[(EventID=845)] and EventData[Data[@Name='ProtectorGUID'] and (Data='$BlProtectorGuid')]]" -MaxEvents 1 -ErrorAction Stop

    # Validate the presence of a backup event; if absent, output a message and exit with a failure code
    if ($BlBackupEvent -ne $null) 
    {
        # Display the event message and terminate the script with success
        Write-Output $BlBackupEvent.Message
        Exit 0
    }
    else 
    {
        Write-Output "No BitLocker recovery key backup event found for the system drive."
        Exit 1
    }
}
catch 
{
    # Handle exceptions by outputting the error message and exiting with a failure code
    $ErrorMessage = $_.Exception.Message
    Write-Output $ErrorMessage
    Exit 1
}
