# Function parameter
param($Timer)

# Azure Powershell modules
Import-Module Az.Accounts
Import-Module Az.Network
Import-Module Az.CosmosDB

# Array of IP address prefixes
$ipRules = @()

# Regular expression of IPv4 IP adsress prefix
$pattern = "^([1-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])){3}(/([0-9]|[12][0-9]|3[0-2])){0,1}$"

# Connect to Azure subscription
Connect-AzAccount -Identity
Set-AzContext -Subscription $env:SubscriptionId
Write-Host "Connected to Azure"

# Get all service tags
$allServiceTags = Get-AzNetworkServiceTag -Location westus2
Write-Host $allServiceTags.Values.Count "service tags found"

# For each allowed service tag, get IPv4 address prefixes
$env:AllowedServiceTags -split "," | ForEach-Object {
    $serviceTag = $_
    $serviceTagValues = $allServiceTags.Values | Where-Object { $_.Name -eq $serviceTag }
    $addressPrefixes = $serviceTagValues.Properties.AddressPrefixes

    $addressPrefixes | ForEach-Object {
        if ($_ -match $pattern) {
            $ipRules += $_
            Write-Host $serviceTag "service tag: " $_
        }
    }
}

# Get IPv4 addresses of Azure Portal
$env:AzurePortalIpAddresses -split "," | ForEach-Object {
    if ($_ -match $pattern) {
        $ipRules += $_
        Write-Host "Azure Portal IP address:" $_
    }
}

# Get additional IPv4 addresses
$env:AdditionalIpAddresses -split "," | ForEach-Object {
    if ($_ -match $pattern) {
        $ipRules += $_
        Write-Host "Additional IP address:" $_
    }
}

# Final array of IPv4 address prefixes
Write-Host $ipRules.Count "IP address prefixes added"

# Update Cosmos DB IP firewall
Update-AzCosmosDBAccount -ResourceGroupName $env:CosmosDbResourceGroup -Name $env:CosmosDbAccount -IpRule $ipRules -AsJob
Write-Host "Cosmos DB IP firewall update request submitted"
