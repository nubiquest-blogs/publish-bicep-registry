/*
* This component is used to deploy SQL server 
*/

/***************************
* Parameters
****************************/

@description('Administrator name')
param administratorLogin string

@description('Administrator password')
@secure()
param administratorPassword string

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
var resourceName = 'sq-${componentName}-${resourceCode}-${location}'

/***************************
* Resources
****************************/

resource sqlServer 'Microsoft.Sql/servers@2024-05-01-preview' = {
  name: resourceName
  location: location
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorPassword
  }
  tags: tags

  resource symbolicname 'firewallRules@2024-05-01-preview' = {
    name: 'AllowAllWindowsAzureIps'
    properties: {
      endIpAddress: '0.0.0.0'
      startIpAddress: '0.0.0.0'
    }
  }
}

/***************************
* Outputs
****************************/

output sqlServerName string = sqlServer.name
