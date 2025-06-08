/*
* This component is used to deploy an app service
*/

/***************************
* Parameters
****************************/

@description('Application additional settings')
@secure()
param additional object

@description('Application insights name')
@secure()
param appInsightSecretUri string

@description('The id of the service plan')
param appServicePlanId string

@description('The component name')
param componentName string

@description('The docker image')
param dockerImage string


@description('The resource location')
param location string

@description('The resource code')
param resourceCode string


@description('The resource tags')
param tags object

/***************************
* Variables
****************************/

var initialSettings = [
  {
    name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'  
    value: '@Microsoft.KeyVault(SecretUri=${appInsightSecretUri})'
  }
  {
    name: 'ASPNETCORE_ENVIRONMENT'  
    value: resourceCode != 'pt' ? 'Production' : 'Test'
  }
]

var finalSettings = union(initialSettings, additional.appSettings)

var resourceName = 'as-${componentName}-${resourceCode}-${location}'

/***************************
* Resources
****************************/

resource app 'Microsoft.Web/sites@2024-04-01' = {
  name: resourceName
  location: location
  kind: 'app,linux,container'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlanId
    siteConfig: {
      linuxFxVersion: 'DOCKER|${dockerImage}'
      acrUseManagedIdentityCreds: true
    }
  }
  tags: tags
}

resource appServiceConfig 'Microsoft.Web/sites/config@2024-04-01' = {
  parent: app
  name: 'web'
  properties: {
    appSettings: finalSettings
  }
}

/***************************
* Outputs
****************************/

output appServiceName string = app.name

output appPrincipalId string = app.identity.principalId
