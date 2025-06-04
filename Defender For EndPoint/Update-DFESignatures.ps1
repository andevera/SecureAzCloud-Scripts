<#
.SYNOPSIS
    Retrieves the latest Microsoft Defender signature version and compares it with the installed version. 
    If the installed version is outdated, it updates the signature.

.DESCRIPTION
    This script checks the currently installed Microsoft Defender antivirus signature version on the local machine 
    and compares it to the latest version available from Microsoft's website. If the installed version is found to be 
    outdated, the script initiates an update to bring the signature version up to date.

.NOTES
    Author: Ankit Gupta
    GitHub: https://github.com/AnkitG365/SecureAzCloud-Scripts/
    LinkedIn: https://www.linkedin.com/in/ankytgupta/

    Version: 1.0
    Created: 12/08/2024

.REQUIREMENTS
    - PowerShell 5.1 or later
    - Internet access to fetch the latest Defender signature version

.EXAMPLE
    .\Update-DefenderSignature.ps1

    This example runs the script to check and update the Microsoft Defender signature version if necessary.
#>

function Get-LatestDefenderVersion {
    # Define the regex pattern to identify and extract the version number
    $Pattern = '<span id="(?<dropdown>.*)" tabindex=(?<tabindex>.*) aria-label=(?<arialabel>.*) versionid=(?<versionid>.*)>(?<version>.*)</span>'
    
    # Retrieve the webpage containing the Microsoft Defender signature version details
    $Url = "https://www.microsoft.com/en-us/wdsi/definitions/antimalware-definition-release-notes"
    $Response = Invoke-WebRequest -Uri $Url -UseBasicParsing
    
    # Extract all version numbers matching the pattern
    $Matches = ($Response.Content | Select-String -Pattern $Pattern -AllMatches).Matches

    # Capture the most recent version from the matches
    $LatestVersion = $Matches[0].Groups["version"].Value
    return $LatestVersion
}

function Get-InstalledDefenderVersion {
    # Retrieve the currently installed Microsoft Defender signature version on the local machine
    $CurrentVersionDevice = (Get-MpComputerStatus).AntivirusSignatureVersion
    return $CurrentVersionDevice
}

function Update-DefenderSignature {
    # Initiate the update process for Microsoft Defender signatures
    Write-Output "Updating Microsoft Defender Signature..."
    Start-Process PowerShell -ArgumentList "Update-MpSignature" -Wait
    Write-Output "Microsoft Defender Signature updated."

    # Get the updated version number after the update process
    $UpdatedVersion = Get-InstalledDefenderVersion
    Write-Output "Updated Defender Signature Version: $UpdatedVersion"
}

# Retrieve the latest and installed version numbers
$InstalledVersion = Get-InstalledDefenderVersion
$LatestVersion = Get-LatestDefenderVersion

# Compare the installed version with the latest version and update if needed
if ($InstalledVersion -ne $LatestVersion) {
    Write-Output "The installed signature version is outdated: $InstalledVersion"
    # Update the Microsoft Defender Signature
    Update-DefenderSignature
    exit 1
} else {
    Write-Output "The installed signature version is current: $InstalledVersion"
    exit 0
}
