<#
.SYNOPSIS
    Retrieves the Microsoft Graph permissions required by commands in a PowerShell script.
.DESCRIPTION
    The `Analyze-GraphScriptPermissions` function analyzes a given script block to identify Microsoft Graph commands. 
    It then retrieves the necessary permissions (scopes) associated with each command using the `Find-MgGraphCommand` function.
    The function returns a list of objects, each representing a command, its source, verb, noun, and the associated permissions.
.PARAMETER Script
    The script block to analyze for Microsoft Graph commands and required permissions.
.EXAMPLE
    $sampleScript = {
        Get-MgUser -Filter "Department eq 'HR'"
        New-MgGroup -DisplayName 'DevOps Team' -Description 'Group for DevOps team'
        Get-MgApplication -Filter "DisplayName eq 'Internal App'"
    }
    Analyze-GraphScriptPermissions -Script $sampleScript
    This example returns the Microsoft Graph permissions required by the commands in the provided script block.
.OUTPUTS
    The function returns objects with the following properties:
    - Command: The command name.
    - Module: The module source of the command.
    - Action: The verb of the command.
    - Resource: The noun of the command.
    - RequiredScopes: A concatenated string of required scopes, indicating whether each requires admin consent.
#>
function Analyze-GraphScriptPermissions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [scriptblock] $Script
    )
    
    begin {
        # Parse the script block into an Abstract Syntax Tree (AST)
        $ParsedAst = [System.Management.Automation.Language.Parser]::ParseInput($Script.ToString(), [ref]$null, [ref]$null)
        [array]$CmdElements = $null

        # Extract all command elements from the AST, along with their associated details
        [array]$CmdElements = $ParsedAst.FindAll({
            $args[0].GetType().Name -like 'CommandAst'
        }, $true) | ForEach-Object {
            [pscustomobject]@{
                Command           = $_.CommandElements[0].Value
                Module            = (Get-Command -Name $_.CommandElements[0].Value).Source
                Action            = (Get-Command -Name $_.CommandElements[0].Value).Verb
                Resource          = (Get-Command -Name $_.CommandElements[0].Value).Noun
                Permissions       = $null
            }
        }
    }
    
    process {
        # List to store final report data
        $GraphPermissionsReport = [System.Collections.Generic.List[Object]]::new()
        # Filter commands to include only those from Microsoft.Graph modules
        [array]$FilteredCommands = $CmdElements | Where-Object Module -like 'Microsoft.Graph*'

        ForEach ($GraphCmd in $FilteredCommands) { 
            [array]$PermissionsArray = $null
            # Retrieve permissions (scopes) required by each Microsoft Graph command
            [array]$RequiredScopes = (Find-MgGraphCommand -Command $GraphCmd.Command | `
                	Select-Object -ExpandProperty Permissions | Sort-Object Name, isAdmin -Unique)
            # Format the scopes as a readable string
            ForEach ($Scope in $RequiredScopes)  {
                $ScopeDetail = ("{0} (Admin Consent: {1})" -f $Scope.Name, $Scope.isAdmin)
                [array]$PermissionsArray += $ScopeDetail
            }
            [string]$PermissionsString = $PermissionsArray -Join ", "
            $ResultObject = [PSCustomObject][Ordered]@{
                Command           = $GraphCmd.Command
                Module            = $GraphCmd.Module
                Action            = $GraphCmd.Action
                Resource          = $GraphCmd.Resource
                RequiredScopes    = $PermissionsString 
            }
            $GraphPermissionsReport.Add($ResultObject) 
        }
        $GraphPermissionsReport | Sort-Object Command -Unique
    }
    
    end {
        # Final cleanup or output (if needed)
    }
}

# Original concept and functionality inspired by Christian Ritter's work, 
# adapted and modified for enhanced scope reporting.
