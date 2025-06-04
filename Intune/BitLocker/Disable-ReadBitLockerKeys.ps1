# This script modifies the authorization policy in Microsoft Entra ID (formerly known as Azure AD)
# to update user role permissions, specifically related to BitLocker self-service recovery.

# Connect to Microsoft Graph with the necessary scope for reading and writing authorization policies
Connect-MgGraph -Scopes Policy.ReadWrite.Authorization

# Define the URI for the authorization policy in Microsoft Entra ID
$authPolicyUri = "https://graph.microsoft.com/beta/policies/authorizationPolicy/authorizationPolicy"

# Construct the body of the request, setting the `allowedToReadBitlockerKeysForOwnedDevice` property
$body = @{
    defaultUserRolePermissions = @{
        allowedToReadBitlockerKeysForOwnedDevice = $false # Set this to $true to allow BitLocker self-service recovery
    }
} | ConvertTo-Json

# Send a PATCH request to update the authorization policy with the specified body
Invoke-MgGraphRequest -Uri $authPolicyUri -Method PATCH -Body $body

# Retrieve and display the current authorization policy settings to verify the change
$authPolicy = Invoke-MgGraphRequest -Uri $authPolicyUri
$authPolicy.defaultUserRolePermissions
  