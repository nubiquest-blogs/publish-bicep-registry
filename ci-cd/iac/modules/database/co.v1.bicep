/*
* This component is used to deploy a Cosmos DB account
*/

/***************************
* Parameters
****************************/

@description('The component name')
param componentName string

@description('If true, free tier will be enabled for this account')
param enableFreeTier bool = true



@description('The resource location')
param location string

@description('Maximun account throughput')
param maxThroughput int = 1000

@description('The resource environment')
param resourceCode string

@description('The resource tags')
param tags object

/***************************
* Variables
****************************/
var resourceName = 'co-${componentName}-${resourceCode}-${location}'

/***************************
* Resources
****************************/

resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2024-11-15' = {
  name: resourceName
  location: location
  properties: {    
    capacity:{
      totalThroughputLimit: maxThroughput
    }
    databaseAccountOfferType: 'Standard'   
    enableFreeTier: enableFreeTier
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
  }
  tags: tags
}

/***************************
* Outputs
****************************/

output cosmosAccountId string = cosmosAccount.id

output cosmosAccountName string = cosmosAccount.name

output cosmosAccountEndpoint string = cosmosAccount.properties.documentEndpoint



