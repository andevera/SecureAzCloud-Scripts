# Set the working directory to C drive and clear the console for better readability
Set-Location C:\
Clear-Host

# Install the Azure module if not already installed
Install-Module -Name Az -Verbose -AllowClobber -Force

# Connect to Azure using the system-assigned managed identity of the VM
Connect-AzAccount -Identity

# Display the current Azure context to verify the connection
$context = Get-AzContext
Write-Output "Connected as: $($context.Account.Id)"

# Retrieve the system-assigned managed identity's principal ID for a specific VM
$VMResourceGroupName = "tw-rg01"
$VMName = "tw-winsrv"
$vmInfo = Get-AzVM -ResourceGroupName $VMResourceGroupName -Name $VMName
$ServicePrincipalId = $vmInfo.Identity.PrincipalId

Write-Output "The managed identity's service principal ID is $ServicePrincipalId"

# Create a storage context to access an Azure Storage Account using the connected account
$StorageAccountName = 'twstg00001'
$StorageContext = New-AzStorageContext -StorageAccountName $StorageAccountName -UseConnectedAccount

# Download a specific blob from the storage container to a local destination
$ContainerName = 'bilder'
$BlobName = 'IMG_0498.jpg'
$DestinationPath = "C:\Temp\"

Get-AzStorageBlobContent -Container $ContainerName -Blob $BlobName `
    -Destination $DestinationPath -Context $StorageContext

Write-Output "Blob $BlobName from container $ContainerName has been downloaded to $DestinationPath"

# Notes:
# - Ensure the VM's managed identity has appropriate permissions on the Storage Account.
# - Consider adding error handling for production scripts.

# Additional connection method (uncomment if using client secrets instead of managed identity):
# Connect-AzAccount -Tenant $TenantID -ClientId $ClientID -ClientSecret $ClientSecret
