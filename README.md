# Automated Bicep File Publishing to Azure Container Registries

## Introduction

Nowadays, **Infrastructure As a Service** is a must-have practice that ensures that the infrastructure deployment is automated and results in consistent results across environments. A lot of tools and languages are used across the industry to enable IaC. [Terraform](https://developer.hashicorp.com/terraform), [CloudFormation](https://aws.amazon.com/cloudformation/) and [Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/) are examples of these languages.

Bicep is the Microsoft language for IaC in Azure. The example below shows the bicep IaC code for the creation of a container registry.

```
/*
* This component is used to deploy a container registry
*/

/***************************
* Parameters
****************************/

@description('Specifies the location for all resources.')
@minLength(2)
param location string 

@description('Container component name')
param componentName string

@description('Environment')
param env string


@description('Specifies the location for all resources.')
param sku string 

@description('The resource tags')
param tags object

/***************************
* Variables
****************************/

// acrs cannot contain dashes
var resourceName = 'cr${componentName}p${env}${location}'

/***************************
* Resources
****************************/

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: resourceName
  location: location
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: true 
  }
  tags: tags
}



/***************************
* Outputs
****************************/


output id string = containerRegistry.id
output name string = containerRegistry.name
output loginServer string = containerRegistry.properties.loginServer
```

Once the infrastructure is described in bicep, the deployment can be done manually using the [az deployment](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-cli) command or ideally using pipeline tasks such as [AzureResourceManagerTemplateDeployment@3](https://learn.microsoft.com/en-us/azure/devops/pipelines/tasks/reference/azure-resource-manager-template-deployment-v3?view=azure-pipelines).

The command below deploys a bicep file to an azure resource group:
```
az deployment group create --resource-group <resource-group-name> --template-file <path-to-bicep>
```

while the task below is an example of an azure devops task (Yml) that deploys a bicep file.
```yml
    - ${{ if eq(parameters.skipValidation, false) }}:
      - task: AzureResourceManagerTemplateDeployment@3
        displayName: "[${{ parameters.appName }}] Validate Resources (${{ parameters.env }})"
        inputs:
            action: "Create Or Update Resource Group"
            azureResourceManagerConnection: ${{ parameters.serviceConnection }}
            csmFile: ${{ parameters.bicepTemplatePath }}
            csmParametersFile: ${{ parameters.bicepTemplateParametersPath }}
            deploymentMode: "Validation"
            deploymentScope: "Resource Group"
            location: ${{ parameters.location }}
            overrideParameters: ${{ parameters.paramOverride }}
            resourceGroupName: ${{ parameters.resourceGroupName }}
            templateLocation: "Linked artifact"
```

## Bicep Modules
Bicep splits the infrastructure code in small component called [modules](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/modules). Modules are ideal for the maintainability and the reusability of the code. 

The code below show how to integrate the container registry module and pass parameters to it:

```bicep
module acrModule './core-acr.bicep' = {
  name: 'dep-compute-${depoymentId}'
  params: {
    deploymentId: depoymentId
    location: commonInputs.location
    registrySku: computeInputs.containerRegistrySku
    tags: commonInputs.tags  
  }
}
```

## The Problem
While modules are perfect for defining scopes responsibility of IaC script, their reuse across projects is quite challenging. 

For example, if I had an infrastructure composed of an application service plan and three application services, modules would be ideal to avoid code duplication as the three app services would be simply created by referencing the module three times with different parameters (such as the name and the tier).

This solves the problem for a single project using a single code repository. However, real life is much more complex. It would be ideal that these modules are reused across projects. 

The expectation is to have a solution:
- that keeps the bicep modules in an accessible and secure store
- that allows the consumers to reuse the modules in their IaC scripts
- that supports versioning of the modules
- That avoids code duplication by copying and pasting bicep code
- That guarantees a readable and clear structure of the bicep repositories

## The Solution
### Step 1 - Azure Container Registries Repositories
The first thought would go to use git repositories as a store for this bicep files. However, this is not ideal as it requires checking out the code every time we need the bicep files. Also, it is very challenging to keep consistent paths across the local environment and the pipeline.

The ideal solution is to use azure container [registry repositories to store bicep files](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/private-module-registry?tabs=azure-cli). Using the ```az publish``` command, it is very easy to publish bicep files to the registry as follows:

```
az bicep publish --file storage.bicep --target br:exampleregistry.azurecr.io/bicep/modules/storage:v1 --documentationUri https://www.contoso.com/exampleregistry.html --with-source
```

It is getting better but it is not enough yet. This solution is not automated, it is not acceptable to do this for hundreds of modules manually. Moreover, there is no clear approach for the structure or the versioning.

### Step 2 - Structure the code
Our bicep files should be in their own github or azure devops repository. To have a strict organization, let's apply this directory structure:
```
ci-cd/ iac / modules / category / files
```
- ```ci-cd/iac/modules``` is a folder that contains the bicep modules
- category is the module category. It can be *compute*, *storage*, *database*,...etc.
- files are the bicep files

Additionally, to ensure versioning, module names should comply with the following naming convention:
```
[module-name].[vx].bicep
```
- ```[module-name]``` is the module name in kebab case
- ```vx``` is the module version number

For example, the folder structure is an example of our bicep files:
```
ci-cd/
└── iac/
    └── modules/
        ├── compute/
        │   ├── ap.v1.bicep
        │   └── ap.v2.bicep
        |   └── as.v1.bicep
        ├── storage/
        │   ├── storage-account.v1.bicep
        │   └── blob-container.v1.bicep
        └── database/
            ├── sql-server.v1.bicep
            └── cosmos-db.v2.bicep
```

The expectation is to have a bicep repository having this name (ap is the abbreviation for app service plan to keep names short):
```
[repository-name].azurecr.io/bm/compute/ap:v1
```

### Automated Publishing
The final part is an automated publishing of the bicep files. This can be for example every time, a pull request is merged in the modules repository. To achieve this, we rely on the following pipeline:

```yml
trigger:
  branches:
    include:
      - main
  paths:
    include:
      - ci-cd/iac
      
parameters:
  - name: location
    displayName: "Location"
    type: string
    default: "East US"
    values:
      - "East US"

  - name: pool
    displayName: "Agent Pool"
    type: string
    default: "Azure Pipelines"
    values:
      - "Azure Pipelines"
      - "SelfPool"         

  - name: serviceConnection
    displayName: "Service Connection Name"
    type: string


variables:

  - group: plc-dev

  - name: containerRegistry
    value: "[YOUR-REGISTRY].azurecr.io"

  - name: vmImage
    value: "ubuntu-latest"


stages:

  - stage: PublishBiceps
    displayName: "Publish Biceps"
    jobs:
      - job: PublishBiceps
        displayName: "Publish Biceps"
        pool:
          name: ${{ parameters.pool }}
          vmImage: $(vmImage)
        steps:

          - task: AzureCLI@2
            displayName: "Publish Bicep Modules to ACR"
            inputs:
              azureSubscription: ${{ parameters.serviceConnection }}
              scriptType: bash
              scriptLocation: inlineScript
              inlineScript: |
                az bicep install

                az config set bicep.use_binary_from_path=False

                find ci-cd/iac/modules -type f | while read -r file; do
                  echo "Publishing $file to ACR..."
                  filename=$(basename "$file")
                  basename=${filename%.*}  # Remove extension
      
                  # Extract parts
                  moduleName=$(echo "$basename" | cut -d'.' -f1)
                  moduleVersion=$(echo "$basename" | cut -d'.' -f2)
                  moduleParent=$(basename $(dirname "$file"))
      

                  az bicep publish --file "$file" --target "br:$(containerRegistry)/bm/$moduleParent/$moduleName:$moduleVersion" --force
      
                done

```

The pipeline extracts the file parts and prepares the repository name. The version will be used as the module tag. For example, for the same module, you can have two versions:

```
[repository-name].azurecr.io/bm/compute/ap:v1
[repository-name].azurecr.io/bm/compute/ap:v2
```

Finally, when run, the repository looks as follows in the registry:

![img](/images/capture.png)

## Consume the Bicep Modules
Finally, once published, the modules are ready to be used across your projects.

The following example shows how to consume the App Service remote module:

```
module myAppModule 'br:[YOUR-REGISTRY].azurecr.io/bm/compute/as:v1' = {
  name: 'dep-app-a0-${deploymentId}'
  params: {
    additional:{
      appSettings:[
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: '${registryName}.azurecr.io'
        }   
        {
          name: 'APP_TAGS'
          value: appTags
        }     
      ]
    }
    appInsightSecretUri: appInsightsSecretUri
    appServicePlanId: appServicePlanId
    componentName: 'a0'
    dockerImage: a0DockerImage
    location: location
    resourceCode: resourceCode
    tags: tags
  }
}
```

- Note that the module url starts with ```br:```

### Bicep Cache
When consuming the bicep modules, bicep stores them in a local cache. Sometimes, if you struggle with getting the last version of a given module, just clear the local cache. For example, in Mac, it would be by removing the files in this folder: 
```
~/.bicep
```