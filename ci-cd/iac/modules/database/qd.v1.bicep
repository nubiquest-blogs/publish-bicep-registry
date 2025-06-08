/*
* This component is used to deploy SQL server 
*/

/***************************
* Parameters
****************************/

@description('The component name')
param componentName string


@description('Database capacity')
param databaseCapacity int

@description('Database max size in bytes')
param databaseMaxSize int = 2147483648

// Basic
@description('Database sku name')
param databaseSku string


@description('The resource location')
param location string

@description('The resource code')
param resourceCode string

@description('SQL Server name')
param sqlServerName string

@description('The resource tags')
param tags object

/***************************
* Variables
****************************/
var resourceName = 'qd-${componentName}-${resourceCode}-${location}'

/***************************
* Resources
****************************/

resource sqlDb 'Microsoft.Sql/servers/databases@2024-05-01-preview' = {
  name: '${sqlServerName}/${resourceName}'
  location: location
  tags: tags
  sku: {
    name: databaseSku
    capacity: databaseCapacity
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: databaseMaxSize
    catalogCollation: 'SQL_Latin1_General_CP1_CI_AS'
    zoneRedundant: false
    readScale: 'Disabled'
    requestedBackupStorageRedundancy: 'Local'
    isLedgerOn: false
    availabilityZone: 'NoPreference'
  }
}
