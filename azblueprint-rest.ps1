# Work with Azure Blueprints with ARM REST API

# Ref: https://timw.info/80132

# Get a bearer token
Connect-AzAccount

$azContext = Get-AzContext

$azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile

$profileClient = New-Object -TypeName Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient -ArgumentList ($azProfile)

$token = $profileClient.AcquireAccessToken($azContext.Subscription.TenantId)
$authHeader = @{
    'Content-Type'  = 'application/json'
    'Authorization' = 'Bearer ' + $token.AccessToken
}

# Invoke the REST API
$restUri = 'https://management.azure.com/subscriptions/2fbf906e-1101-4bc0-b64f-adc44e462fff?api-version=2020-01-01'
$response = Invoke-RestMethod -Uri $restUri -Method Get -Headers $authHeader

# Create a blueprint
PUT https://management.azure.com/providers/Microsoft.Management/managementGroups/ { YourMG }/providers/Microsoft.Blueprint/blueprints/MyBlueprint?api-version=2018-11-01-preview

# Add artifact
PUT https://management.azure.com/providers/Microsoft.Management/managementGroups/ { YourMG }/providers/Microsoft.Blueprint/blueprints/MyBlueprint/artifacts/roleContributor?api-version=2018-11-01-preview

# Publish blueprint
PUT https://management.azure.com/providers/Microsoft.Management/managementGroups/ { YourMG }/providers/Microsoft.Blueprint/blueprints/MyBlueprint/versions/ { BlueprintVersion }?api-version=2018-11-01-preview

# Assign a blueprint
GET https://graph.windows.net/ { tenantId }/servicePrincipals?api-version=1.6&$filter = appId eq 'f71766dc-90d9-4b7d-bd9d-4499c4331c3f'

PUT https://management.azure.com/subscriptions/ { subscriptionId }/providers/Microsoft.Blueprint/blueprintAssignments/assignMyBlueprint?api-version=2018-11-01-preview

# Cleanup: Unassign the blueprint
DELETE https://management.azure.com/subscriptions/ { subscriptionId }/providers/Microsoft.Blueprint/blueprintAssignments/assignMyBlueprint?api-version=2018-11-01-preview

# Cleanup: Delete the blueprint
DELETE https://management.azure.com/providers/Microsoft.Management/managementGroups/ { YourMG }/providers/Microsoft.Blueprint/blueprints/MyBlueprint?api-version=2018-11-01-preview