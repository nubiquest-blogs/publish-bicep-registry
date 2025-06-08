/*
* This component is used to deploy a queue in a storage account
*/

/***************************
* Parameters
****************************/

@description('The queue name')
param queueName string

@description('The queue service name')
param queueServiceName string

@description('The storage account name')
param storageAccountName string



/***************************
* Variables
****************************/



/***************************
* Resources
****************************/



resource queueService 'Microsoft.Storage/storageAccounts/queueServices@2024-01-01' existing = {
  name: '${storageAccountName}/${queueServiceName}'
}

resource queue 'Microsoft.Storage/storageAccounts/queueServices/queues@2024-01-01' = {
  name: queueName
  parent: queueService
  properties: {
    metadata: {
      
    }
  }
}
/***************************
* Outputs
****************************/

