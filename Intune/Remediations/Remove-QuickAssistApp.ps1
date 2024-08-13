<#
.SYNOPSIS
    This script detects and removes Microsoft Quick Assist if installed on the system.

.DESCRIPTION
    The script serves two purposes: 
    1. Detect if Microsoft Quick Assist is installed for the current user.
    2. Remove Microsoft Quick Assist if it is found, both from the current user's installation and as a provisioned app, to prevent future installations for new users.

.EXAMPLE
    .\Remove-QuickAssistApp.ps1
    If installed, this example runs the script to detect and remove Microsoft Quick Assist.

.NOTES
    Author: Ankit Gupta
    Version: 1.0 - 12-Aug-2024

    Always validate and test scripts in a non-production environment before deploying them in your organization.

#>

# Define the app package name
$PackageName = "MicrosoftCorporationII.QuickAssist"

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
        Write-Output "Removed app package $PackageName for the current user."
    } else {
        Write-Output "App package $PackageName not found for the current user."
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

# Execute the detection and removal functions
if (Test-AppxPackage -PackageName $PackageName) {
    Write-Output "Microsoft Quick Assist is installed. Proceeding with removal."
    
    # Remove Quick Assist for the current user
    Remove-AppxPackageByName -PackageName $PackageName
    
    # Remove the provisioned package so it does not get installed for new users
    Remove-AppxProvisionedPackageByName -PackageName $PackageName
    
    Write-Output "Microsoft Quick Assist removal process completed."
} else {
    Write-Output "Microsoft Quick Assist is not installed on this system."
}
