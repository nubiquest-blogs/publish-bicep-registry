/*
* This component is used to deploy a container registry
*/

/***************************
* Parameters
****************************/

@description('Specifies the location for all resources.')
@minLength(2)
param location string 

@description('Container component name')
param componentName string

@description('Environment')
param env string


@description('Specifies the location for all resources.')
param sku string 

@description('The resource tags')
param tags object

/***************************
* Variables
****************************/

// acrs cannot contain dashes
var resourceName = 'cr${componentName}p${env}${location}'

/***************************
* Resources
****************************/

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: resourceName
  location: location
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: true 
  }
  tags: tags
}



/***************************
* Outputs
****************************/


output id string = containerRegistry.id
output name string = containerRegistry.name
output loginServer string = containerRegistry.properties.loginServer
