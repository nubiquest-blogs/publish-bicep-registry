/*
* This component is used to deploy a function app
*/

/***************************
* Parameters
****************************/

@description('Application additional settings')
@secure()
param additional object

@description('The name of the app insights')
param appInsightsName string

@description('The id of the service plan')
param appServicePlanId string

@description('The component name')
param componentName string

@description('The key vault name')
param keyVaultName string

@description('Linux FX version')
param linuxFxVersion string

@description('The resource location')
param location string

@description('The resource code')
param resourceCode string

@description('The storage account name')
param storageAccountName string

@description('Storage secret name')
@secure()
param storageSecretName string

@description('The resource tags')
param tags object

/***************************
* Variables
****************************/

var resourceName = 'fn-${componentName}-${resourceCode}-${location}'

/***************************
* Resources
****************************/

// 1- get a reference to the storage account
/* For now, key vault is not supported in WEBSITE_CONTENTAZUREFILECONNECTIONSTRING*/

resource storageAccount 'Microsoft.Storage/storageAccounts@2024-01-01' existing={
  name: storageAccountName
}


// 2- get a reference to the application insights
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
}

// 3 - get a reference to the storage secret

resource storageSecret 'Microsoft.KeyVault/vaults/secrets@2024-11-01' existing = {
  name: '${keyVaultName}/${storageSecretName}'
}


// 4 - create the function app

resource functionApp 'Microsoft.Web/sites@2024-04-01' = {
  name: resourceName
  location: location
  kind: 'functionapp,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlanId
    siteConfig: {
      appSettings: union([
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: applicationInsights.properties.InstrumentationKey
        }
        {
          name: 'AzureWebJobsStorage'
          value: '@Microsoft.KeyVault(SecretUri=${storageSecret.properties.secretUri})'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet-isolated'
        }              
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(resourceName)
        }      
      ], additional.appSettings)
      ftpsState: 'FtpsOnly'
      linuxFxVersion: linuxFxVersion
      minTlsVersion: '1.2'
    }
    httpsOnly: true
  }
  tags: tags
}



/***************************
* Outputs
****************************/

output functionAppName string = functionApp.name

output functionAppPrincipalId string = functionApp.identity.principalId
