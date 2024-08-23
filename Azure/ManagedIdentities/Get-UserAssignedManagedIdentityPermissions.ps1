# This script lists the user-assigned managed identities in your Azure subscription
# and outputs their associated role assignments and permissions.

# Install the Az module if it is not already installed
Install-Module -Name Az -Force -AllowClobber -Verbose

# Log into Azure using your credentials
Connect-AzAccount

# Retrieve all user-assigned managed identities in the subscription
$UserAssignedIdentities = Get-AzUserAssignedIdentity

# Output the count and names of the user-assigned managed identities
Write-Host "There are $($UserAssignedIdentities.Count) user-assigned managed identities in your subscription:"
foreach ($UserAssignedIdentity in $UserAssignedIdentities) {
    Write-Host "- $($UserAssignedIdentity.Name)"
}

# For each user-assigned managed identity, retrieve and display the role assignments
foreach ($UserAssignedIdentity in $UserAssignedIdentities) {
    Write-Host "Permissions for $($UserAssignedIdentity.Name):"
    
    # Get the role assignments associated with the identity's PrincipalId
    $RoleAssignments = Get-AzRoleAssignment -ObjectId $UserAssignedIdentity.PrincipalId
    
    # Loop through each role assignment and display the role definition name
    foreach ($RoleAssignment in $RoleAssignments) {
        $RoleDefinition = Get-AzRoleDefinition -Id $RoleAssignment.RoleDefinitionId
        Write-Host "- $($RoleDefinition.Name)"
    }
}
