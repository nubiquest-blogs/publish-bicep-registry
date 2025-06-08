/*
* This component is used to deploy an app service plan
*/

/***************************
* Parameters
****************************/
@description('The sku of the app service plan')
param appServicePlanSku string

@description('The component name')
param componentName string

@description('The resource location')
param location string

@description('The resource code')
param resourceCode string


@description('The resource tags')
param tags object

/***************************
* Variables
****************************/

var resourceName = 'ap-${componentName}-${resourceCode}-${location}'

/***************************
* Resources
****************************/

resource appServicePlan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: resourceName
  location: location
  kind: 'linux'  
  properties: {
    perSiteScaling: false
    elasticScaleEnabled: false
    maximumElasticWorkerCount: 1
    isSpot: false
    reserved: true
    isXenon: false
    hyperV: false
    targetWorkerCount: 0
    targetWorkerSizeId: 0
    zoneRedundant: false
  }
  sku: {
    name: appServicePlanSku
  }
  tags: tags
}

/***************************
* Outputs
****************************/

output appServicePlanId string = appServicePlan.id
output appServicePlanName string = appServicePlan.name

