/*
* This component is used to deploy a Blob service in a storage account
*/

/***************************
* Parameters
****************************/

@description('The Blob service name')
param blobServiceName string = 'default'

@description('The storageName')
param storageAccountName string


/***************************
* Resources
****************************/

resource storageAccount 'Microsoft.Storage/storageAccounts@2024-01-01' existing = {
  name: storageAccountName
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2024-01-01' = {
  name: blobServiceName
  parent: storageAccount  
}

/***************************
* Outputs
****************************/

output blobServiceName string = blobService.name
