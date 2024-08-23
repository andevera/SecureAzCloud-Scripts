<#
.SYNOPSIS
    This script analyzes Group Policy Objects (GPOs) to identify those linked to Organizational Units (OUs) that are empty (i.e., contain no non-OU objects).

.DESCRIPTION
    The script scans through all Organizational Units (OUs) that have linked Group Policy Objects (GPOs) and checks if those OUs are empty. It identifies GPOs linked exclusively to empty OUs and those linked to both empty and non-empty OUs, assisting in identifying potentially redundant GPOs.

.PARAMETER Filter
    A filter to apply when searching OUs. By default, it searches all OUs.

.EXAMPLE
    Get-GPOAnalysis -Verbose | Format-List
    This example retrieves and displays the status of GPOs linked to OUs with verbose output.

.NOTES
    Author: Ankit Gupta
    Version: 1.1 - 24-Aug-2024
    GitHub: https://github.com/AnkitG365/SecureAzCloud-Scripts
#>

# Function to analyze OUs and check their contents
function Analyze-OUStatus {
    param (
        [string]$OUFilter = '*'
    )

    ForEach($OU in Get-ADOrganizationalUnit -Filter $OUFilter) {
        $containedObjects = Get-ADObject -Filter {ObjectClass -ne 'OrganizationalUnit'} -SearchBase $OU.DistinguishedName -ErrorAction SilentlyContinue

        if ($containedObjects) {
            [pscustomobject]@{
                OUName    = $OU
                IsEmpty   = $false
                LinkedGPOs = $OU.LinkedGroupPolicyObjects
            }
        } else {
            [pscustomobject]@{
                OUName    = $OU
                IsEmpty   = $true
                LinkedGPOs = $OU.LinkedGroupPolicyObjects
            }
        }
    }
}

# Main function to assess the status of GPOs linked to OUs
function Get-GPOAnalysis {
    [cmdletbinding()]
    param()

    $AnalyzedOUs = Analyze-OUStatus | Where-Object {$_.LinkedGPOs}
    $GPOsLinkedToEmptyOUs = @()

    # Evaluate OUs that are empty
    ForEach($OU in ($AnalyzedOUs | Where-Object {$_.IsEmpty}).OUName) {
        ForEach($GPOGuid in $OU.LinkedGroupPolicyObjects) {
            $GPO = Get-GPO -Guid $GPOGuid.Substring(4,36)
            Write-Verbose "GPO: '$($GPO.DisplayName)' is linked to empty OU: $($OU.Name)"

            if ($GPOsLinkedToEmptyOUs.GPOId -contains $GPO.Id) {
                ForEach($LinkedGPO in ($GPOsLinkedToEmptyOUs | Where-Object {$_.GPOId -eq $GPO.Id})){
                    $LinkedGPO.EmptyOUs = [string[]]$LinkedGPO.EmptyOUs + "$($OU.DistinguishedName)"
                }
            } else {
                $GPOsLinkedToEmptyOUs += [PSCustomObject]@{
                    GPOName   = $GPO.DisplayName
                    GPOId     = $GPO.Id
                    EmptyOUs  = $OU.DistinguishedName
                    NonEmptyOUs = ''
                }
            }
        }
    }

    # Evaluate OUs that are not empty
    ForEach($OU in ($AnalyzedOUs | Where-Object {-not $_.IsEmpty}).OUName) {
        ForEach($GPO in $GPOsLinkedToEmptyOUs) {
            ForEach($GPOGuid in $OU.LinkedGroupPolicyObjects) {
                if ($GPOGuid.Substring(4,36) -eq $GPO.GPOId) {
                    Write-Verbose "GPO: '$($GPO.GPOName)' also linked to non-empty OU: $($OU.Name)"

                    if ($GPO.NonEmptyOUs) {
                        $GPO.NonEmptyOUs = [string[]]$GPO.NonEmptyOUs + $OU.DistinguishedName
                    } else {
                        $GPO.NonEmptyOUs = $OU.DistinguishedName
                    }
                }
            }
        }
    }

    $GPOsLinkedToEmptyOUs
}

# Usage example
Get-GPOAnalysis -Verbose | Format-List

# Identifying GPOs that are linked only to empty OUs
$UnusedGPOs = Get-GPOAnalysis | Where-Object {$_.EmptyOUs -and -not $_.NonEmptyOUs}
$UnusedGPOs | Format-List

# The above command outputs GPOs that are only linked to empty OUs and may need to be reviewed for potential decommissioning.
