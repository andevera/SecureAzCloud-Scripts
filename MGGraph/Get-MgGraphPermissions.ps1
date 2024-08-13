<#
    .SYNOPSIS
        Retrieves the Microsoft Graph permissions required to execute a set of specified cmdlets.

    .DESCRIPTION
        This script analyzes a list of provided cmdlets and returns the necessary Microsoft Graph permissions 
        that are required to run these cmdlets successfully. This is useful for identifying permissions needed 
        for scripts or command sequences.

    .NOTES
        Author: Ankit Gupta
        Last Modified: 2024-08-12
        Version: 1.0

    .EXAMPLE
        .\Find-GraphPermissions.PS1

        This example returns the required permissions for the specified cmdlets.
#>

# Define the list of cmdlets to check for required permissions
[array]$CmdletsToCheck = "Get-MgUser", "Get-MgGroup", "New-MgPlannerTask"
[array]$PermissionsNeeded = @()

# Loop through each cmdlet to find and collect the required permissions
ForEach ($Cmdlet in $CmdletsToCheck) {
    $CmdletPermissions = (Find-MgGraphCommand -Command $Cmdlet | Select-Object -ExpandProperty Permissions).Name
    ForEach ($Permission in $CmdletPermissions) {
        If ($Permission -notin $PermissionsNeeded) {
            $PermissionsNeeded += $Permission
        }
    }
}

# Display the required permissions for the cmdlets
Write-Host ("To execute the following cmdlets: {0}, the necessary permissions are: {1}" -f ($CmdletsToCheck -join ", "), ($PermissionsNeeded -join ", "))

# Reminder: Always validate the permissions and cmdlets in a non-production environment before applying them to production.
