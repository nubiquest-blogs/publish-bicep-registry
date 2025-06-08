/*
* This component is used to deploy a Cosmos database
*/

/***************************
* Parameters
****************************/

@description('Cosmos account name')
param cosmosAccountName string

@description('Cosmos account name')
param databaseName string

/***************************
* Resources
****************************/

resource database 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2024-11-15' = {
  name: '${cosmosAccountName}/${databaseName}'
  properties: {
    resource: {
      id: databaseName    
    }
  }  
}

/***************************
* Outputs
****************************/

output databaseName string = database.name
