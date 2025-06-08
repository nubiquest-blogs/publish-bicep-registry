/*
* This component is used to deploy a queue service in a storage account
*/

/***************************
* Parameters
****************************/

@description('The queue name')
param queueServiceName string = 'default'

@description('The storageName')
param storageAccountName string


/***************************
* Resources
****************************/

resource storageAccount 'Microsoft.Storage/storageAccounts@2024-01-01' existing = {
  name: storageAccountName
}

resource queueService 'Microsoft.Storage/storageAccounts/queueServices@2024-01-01' = {
  name: queueServiceName
  parent: storageAccount  
}

/***************************
* Outputs
****************************/

output queueServiceName string = queueService.name

