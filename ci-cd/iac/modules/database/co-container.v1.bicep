/*
* This component is used to deploy a Cosmos DB container
*/

/***************************
* Parameters
****************************/

@description('Database name')
param databaseName string

@description('The component name')
param containerName string

@description('Maximum container throughput')
param throughput int = 400

@description('Partition key')
param partitionKey array


/***************************
* Resources
****************************/

resource dbContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2024-11-15' = {
  name: '${databaseName}/${containerName}'  
  properties: {
    options:{
     throughput: throughput
    }
    resource: {
      id: containerName          
      indexingPolicy: {
        indexingMode: 'consistent'
        automatic: true
        includedPaths: [
          {
            path: '/*'
          }
        ]
        excludedPaths: [
          {
            path: '/"_etag"/?'
          }
        ]
      }
      partitionKey: {
        paths: partitionKey
      }
    }
  }
}
