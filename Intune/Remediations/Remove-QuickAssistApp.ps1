<#
.SYNOPSIS
    This script detects and removes Microsoft Quick Assist if installed on the system.

.DESCRIPTION
    The script serves two purposes: 
    1. Detect if Microsoft Quick Assist is installed for the current user.
    2. Remove Microsoft Quick Assist if it is found, both from the current user's installation and as a provisioned app to prevent future installations for new users.

.EXAMPLE
    .\Manage-QuickAssist.PS1
    This example runs the script to detect and remove Microsoft Quick Assist if installed.

.NOTES
    Author: Ankit Gupta
    Version: 1.0 - 12-Aug-2024

    Always validate and test scripts in a non-production environment before deploying them in your organization.

#>

# Define the app package name
$appPackageName = "MicrosoftCorporationII.QuickAssist"

# Function to check if the app is installed for the current user
function Test-AppxPackage {
    param (
        [string]$PackageName
    )

    $app = Get-AppxPackage -Name $PackageName -ErrorAction SilentlyContinue
    return $app -ne $null
}

# Function to remove the app for the current user
function Remove-AppxPackageByName {
    param (
        [string]$PackageName
    )

    $app = Get-AppxPackage -Name $PackageName -ErrorAction SilentlyContinue
    if ($app) {
        Remove-AppxPackage -Package $app.PackageFullName -ErrorAction SilentlyContinue
        Write-Output "Removed app package $PackageName for current user."
    } else {
        Write-Output "App package $PackageName not found for current user."
    }
}

# Function to remove the provisioned app
function Remove-AppxProvisionedPackageByName {
    param (
        [string]$PackageName
    )

    $app = Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq $PackageName}
    if ($app) {
        Remove-AppxProvisionedPackage -Online -PackageName $app.PackageName -ErrorAction SilentlyContinue
        Write-Output "Removed provisioned app package $PackageName."
    } else {
        Write-Output "Provisioned app package $PackageName not found."
    }
}

# Detect if Microsoft Quick Assist is installed
if (Test-AppxPackage -PackageName $appPackageName) {
    Write-Output "Microsoft Quick Assist is installed. Proceeding with removal."
    
    # Remove Quick Assist for the current user
    Remove-AppxPackageByName -PackageName $appPackageName
    
    # Remove the provisioned package so it does not get installed for new users
    Remove-AppxProvisionedPackageByName -PackageName $appPackageName
    
    Write-Output "Microsoft Quick Assist removal process completed."
} else {
    Write-Output "Microsoft Quick Assist is not installed on this system."
}
