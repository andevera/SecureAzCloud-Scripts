<#
.SYNOPSIS
    This script is used to delete a custom Threat Intelligence (TI) Indicator by Name in your Azure Sentinel.

.DESCRIPTION
    This PowerShell script connects to Azure Sentinel through the Azure PowerShell (Az) module and deletes a specified 
    Threat Intelligence (TI) Indicator from a Log Analytics workspace. The script requires the workspace name, resource group, 
    and the indicator's unique identifier (GUID) as inputs. 

    The script performs the following actions:
    - Connects to Azure using a certificate for authentication.
    - Retrieves the Log Analytics workspace ID.
    - Deletes the specified Threat Intelligence Indicator using its GUID.

.NOTES
    Author        : Ankit Gupta
    Version       : 1.0.0.0
    Created       : 12/08/2024
    Prerequisite  : Azure PowerShell (Az) module

.EXAMPLE
    .\Delete-AzThreatIntelligenceIndicatorById.ps1 -WorkspaceRg "your-resource-group" `
                                                   -WorkspaceName "your-workspace-name" `
                                                   -IndicatorName "6a36e7f1-20ee-39f2-958d-90a6994188d"

    This example deletes the Threat Intelligence Indicator with the specified GUID from the given Log Analytics workspace.
#>

# Connect to Azure with your certificate and tenant details
Connect-AzAccount -CertificateThumbprint "<Your-Certificate-Thumbprint>" -Tenant "<Your-Tenant-ID>" -ApplicationId "<Your-Application-ID>"

Function Delete-AzThreatIntelligenceIndicatorById
{
    Param(
        [Parameter(Mandatory = $true,
                   HelpMessage = "Resource group name of the Log Analytics workspace Azure Sentinel connects to",
                   Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]
        $WorkspaceRg,

        [Parameter(Mandatory = $true,
                   HelpMessage = "Name of the Log Analytics workspace Azure Sentinel connects to",
                   Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]
        $WorkspaceName,

        [Parameter(Mandatory = $true,
                   HelpMessage = "Name (GUID) of the Indicator",
                   Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]
        $IndicatorName
    )

    $workspaceId = (Get-AzOperationalInsightsWorkspace -Name $WorkspaceName `
                                                       -ResourceGroupName $WorkspaceRg).ResourceId
    if (!$workspaceId) {
        Write-Host -ForegroundColor Red "[!] Workspace cannot be found. Please try again"
    }
    else {
        Write-Host -ForegroundColor Green "[-] Your Azure Sentinel is connected to workspace: $WorkspaceName"
    }

    $accessToken = Get-AzAccessToken -ResourceTypeName "ResourceManager"
    $authHeader = @{
        'Content-Type'  = 'application/json'
        'Authorization' = 'Bearer ' + $accessToken.Token
    }

    $uri = "https://management.azure.com" + $workspaceId `
                                          + "/providers/Microsoft.SecurityInsights/ThreatIntelligence/" `
                                          + $IndicatorName `
                                          + "?api-version=2021-04-01"

    $response = Invoke-RestMethod -Uri $uri `
                                  -Method Delete `
                                  -Headers $authHeader
}
