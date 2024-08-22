<#
.SYNOPSIS
    Script to remove unwanted apps and set registry keys for system optimization.

.DESCRIPTION
    This script prompts the user for confirmation before removing specified apps and setting registry keys. It is designed to help clean up unwanted applications and optimize system settings.

.PARAMETER AppName
    The name of the app to be removed.

.PARAMETER Path
    The registry path where the key is to be set.

.PARAMETER Name
    The name of the registry key to be set.

.PARAMETER Value
    The value to set for the specified registry key.

.EXAMPLE
    .\Remove-BloatWare.ps1
    This command runs the script and prompts the user to confirm the removal of apps and setting of registry keys.

.NOTES
    Author: Ankit Gupta
    GitHub: https://github.com/ankytgupta

    Always validate and test scripts in a non-production environment before deploying them in your organization.
#>

# Function to prompt the user for confirmation
function Confirm-Action {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message
    )
    $confirmation = Read-Host "$Message (y/n)"
    return $confirmation -eq 'y'
}

# Function to remove a given app
function Remove-App {
    param (
        [Parameter(Mandatory = $true)]
        [string]$AppName
    )
    if (Confirm-Action -Message "Do you want to remove $AppName?") {
        Get-AppxPackage -Name $AppName | Remove-AppxPackage -ErrorAction SilentlyContinue
        Write-Output "$AppName removed."
    } else {
        Write-Output "Skipped removing $AppName."
    }
}

# List of apps to remove (customize this list as needed)
$appsToRemove = @(
    "Microsoft.3DBuilder", 
    "Microsoft.BingWeather", 
    "Microsoft.GetHelp", 
    "Microsoft.Getstarted", 
    "Microsoft.Microsoft3DViewer", 
    "Microsoft.MicrosoftOfficeHub",
    "Microsoft.MicrosoftSolitaireCollection", 
    "Microsoft.MixedReality.Portal", 
    "Microsoft.People", 
    "Microsoft.Print3D", 
    "Microsoft.SkypeApp", 
    "Microsoft.WindowsAlarms", 
    "Microsoft.WindowsFeedbackHub",
    "Microsoft.WindowsMaps", 
    "Microsoft.WindowsSoundRecorder", 
    "Microsoft.XboxApp", 
    "Microsoft.XboxGameOverlay", 
    "Microsoft.XboxGamingOverlay", 
    "Microsoft.XboxIdentityProvider", 
    "Microsoft.XboxSpeechToTextOverlay"
)

# Loop through app list and prompt for removal
foreach ($app in $appsToRemove) {
    Remove-App -AppName $app
}

# Function to set a registry key value
function Set-RegistryKey {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [string]$Value
    )
    if (Confirm-Action -Message "Do you want to set $Name in $Path to $Value?") {
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -ErrorAction SilentlyContinue
        Write-Output "Set $Name in $Path to $Value."
    } else {
        Write-Output "Skipped setting $Name in $Path."
    }
}

# Disable telemetry using the registry
Set-RegistryKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0

Write-Output "Windows Debloat completed."
