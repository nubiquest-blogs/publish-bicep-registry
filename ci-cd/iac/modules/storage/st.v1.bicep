/*
* This component is used to deploy a storage account
*/

/***************************
* Parameters
****************************/


@description('The storage sku')
param sku string = 'Standard_LRS'

@description('The resource location')
param location string

param storageAccountName string

@description('The resource tags')
param tags object

/***************************
* Variables
****************************/



/***************************
* Resources
****************************/

resource storageAccount 'Microsoft.Storage/storageAccounts@2024-01-01'={
  name: storageAccountName
  location: location
  sku: {
    name: sku
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
  }
  tags: tags
}


/***************************
* Outputs
****************************/

output storageName string = storageAccount.name


