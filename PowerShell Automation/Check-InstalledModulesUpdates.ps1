<#
.SYNOPSIS
    This script inspects all installed PowerShell modules and determines if there are newer versions available in the PSGallery.
    It allows filtering of modules by name and checks for updates in manageable batches.

.DESCRIPTION
    The `Check-ModuleUpdates` script is a useful tool for maintaining up-to-date PowerShell modules. 
    By specifying a name pattern, users can filter which modules to check for updates. 
    The script connects to PSGallery to retrieve the latest module versions and compares them to the installed versions.

.PARAMETER NameFilter
    A wildcard pattern to filter the modules by name. Defaults to '*' which matches all modules.

.EXAMPLE
    .\Check-InstalledModulesUpdates -NameFilter '*Az*'
    This example filters modules by names that contain 'Az' and checks if any have updates available.

.NOTES
    Author: Ankit Gupta
    Version: 1.0 - 25-Aug-2024
    GitHub Link: https://github.com/AnkitG365/SecureAzCloud-Scripts

    This script is intended for use in a controlled environment. Test thoroughly before deploying in production.

#>

param (
    [Parameter(Mandatory = $false)]
    [string]$ModuleFilter = '*'
)

# Fetch the installed modules based on the provided filter
Write-Host ("Searching for installed PowerShell modules matching pattern '$ModuleFilter'...") -ForegroundColor Cyan
[array]$LocalModules = Get-InstalledModule -Name $ModuleFilter -ErrorAction SilentlyContinue

# Initialize a collection to hold the latest online versions
$latestOnlineVersions = @()

# Process single or multiple modules, fetching their latest versions from PSGallery
if ($LocalModules.Count -eq 1) {
    Write-Host ("Retrieving online version for installed module {0}..." -f $LocalModules.Name) -ForegroundColor Cyan
    $moduleVersion = Find-Module -Name $LocalModules.Name
    $latestOnlineVersions += $moduleVersion
} elseif ($LocalModules.Count -gt 1) {
    $batchSize = 63
    $currentBatchStart = 0
    $currentBatchEnd = $batchSize - 1

    while ($LocalModules.Count -gt $latestOnlineVersions.Count) {
        Write-Host ("Fetching online versions for installed modules batch [{0}..{1}/{2}]..." -f $currentBatchStart, $currentBatchEnd, $LocalModules.Count) -ForegroundColor Cyan
        $batchVersions = Find-Module -Name $LocalModules.Name[$currentBatchStart..$currentBatchEnd]
        $currentBatchStart += $batchSize
        $currentBatchEnd += $batchSize
        $latestOnlineVersions += $batchVersions
    }
}

# Exit if no matching modules are found
if (-not $latestOnlineVersions) {
    Write-Warning ("No matching modules found for the filter '$ModuleFilter'. Exiting script.")
    return
}

# Compare installed versions with online versions and list those that have updates available
Write-Host ("Comparing installed module versions with PSGallery...") -ForegroundColor Cyan
$modulesWithUpdates = foreach ($mod in $LocalModules) {
    Write-Progress -Activity ("Inspecting module {0}" -f $mod.Name) -Status ("[{0}/{1}]" -f ($LocalModules.IndexOf($mod) + 1), $LocalModules.Count)
    try {
        $psGalleryMod = $latestOnlineVersions | Where-Object Name -eq $mod.Name
        if ([version]$mod.Version -lt [version]$psGalleryMod.Version) {
            [PSCustomObject]@{
                Repository          = $mod.Repository
                'Module Name'       = $mod.Name
                'Installed Version' = $mod.Version
                'Latest Version'    = $psGalleryMod.Version
                'Published On'      = $psGalleryMod.PublishedDate
            }
        }
    } catch {
        Write-Warning ("Unable to locate module '{0}' in PSGallery." -f $mod.Name)
    }
}

# Display the results, showing modules with available updates
if ($modulesWithUpdates.Count -gt 0) {
    Write-Host ("Discovered {0} modules with available updates." -f $modulesWithUpdates.Count) -ForegroundColor Green
    $modulesWithUpdates | Format-Table -AutoSize
} else {
    Write-Host ("All installed modules are up-to-date.") -ForegroundColor Green
}
