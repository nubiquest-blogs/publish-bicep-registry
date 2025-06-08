/*
* This component is used to deploy a blob container in a storage account
*/

/***************************
* Parameters
****************************/


@description('The queue service name')
param blobServiceName string

@description('The queue name')
param containerName string


@description('The storage account name')
param storageAccountName string



/***************************
* Variables
****************************/



/***************************
* Resources
****************************/



resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2024-01-01' existing = {
  name: '${storageAccountName}/${blobServiceName}'
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2024-01-01' = {
  name: containerName
  parent: blobService
  properties: {
    metadata: {
      
    }
  }
}
/***************************
* Outputs
****************************/

