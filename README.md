# CAN WE DEPLOY AZ B2C USING TERRAFORM AND DEVOPS

Greetings my fellow Technology Advocates and Specialists.

In this Session, I will demonstrate - 
1. How to Validate Pre-Requisites of Azure B2C Tenant using DevOps. 
2. If Azure B2C Tenant Deployment is Possible using Terraform and DevOps.  

| __REQUIREMENTS:-__ |
| --------- |

1. Azure Subscription.
2. Azure DevOps Organisation and Project.
3. Service Principal with Delegated Graph API Rights and Required RBAC (Typically __Contributor__ on Subscription or Resource Group)
3. Azure Resource Manager Service Connection in Azure DevOps.
4. Microsoft DevLabs Terraform Extension Installed in Azure DevOps.

| __USE CASE #1:-__ |
| --------- |
| Validate Pre-Requisites of Azure B2C Tenant using DevOps |

| __PIPELINE DETAILS FOLLOW BELOW:-__ |
| --------- |

1. This is a __Single Stage__ Pipeline with 3 Runtime Variables - 1) Subscription ID 2) Service Connection Name 3) Name of Azure B2C Tenant (This is the Only User Input Runtime Variable) 
2. The Stage Checks for 2 Conditions: 1)If the __Provider is Registered in the Subscription__ 2)If the __B2C Name Provided by the user is Globally Unique__. If Both Conditions are __NOT__ met, Pipeline Fails, else the pipeline succeeds confirming that the Azure B2C Tenant Name can be used for Deployment. 


| __HOW DOES MY CODE PLACEHOLDER LOOKS LIKE:-__ |
| --------- |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/f7gf9gnxyg0uvdi9o006.png) |


| AZURE DEVOPS YAML PIPELINE (azure-pipelines-B2C-v1.0.yml):- | 
| --------- |

```
trigger:
  none

######################
#DECLARE PARAMETERS:-
######################
parameters:
- name: SubscriptionID
  displayName: Subscription ID Details Follow Below:-
  default: 210e66cb-55cf-424e-8daa-6cad804ab604
  values:
  -  210e66cb-55cf-424e-8daa-6cad804ab604

- name: ServiceConnection
  displayName: Service Connection Name Follows Below:-
  default: amcloud-cicd-service-connection
  values:
  -  amcloud-cicd-service-connection

- name: AADB2CName
  displayName: Please Provide the AAD B2C Tenant Name:-
  type: object
  default: <Please Provide the Name of AAD B2C>

######################
#DECLARE VARIABLES:-
######################
variables:
  AADExists: AlreadyExists
  AADProvider: NotRegistered
  BuildAgent: windows-latest
  
#########################
# Declare Build Agents:-
#########################
pool:
  vmImage: $(BuildAgent)

###################
# Declare Stages:-
###################
stages:

- stage: VALIDATE_AAD_B2C_PROVIDER_AND_NAME
   
  jobs:
  - job: IF_AAD_B2C_PROVIDER_AND_NAME_EXISTS 
    displayName: IF AAD B2C PROVIDER AND NAME EXISTS
    steps:
    - task: AzureCLI@2
      displayName: CHECK AAD B2C PROVIDER AND NAME
      inputs:
        azureSubscription: ${{ parameters.ServiceConnection }}
        scriptType: ps
        scriptLocation: inlineScript
        inlineScript: |
          az --version
          az account set --subscription ${{ parameters.SubscriptionID }}
          az account show  
          $B2CJSON = @{
              countryCode = "CH"
              name = "${{ parameters.AADB2CName }}" 
            }
          $infile = "B2CDetails.json"
          Set-Content -Path $infile -Value ($B2CJSON | ConvertTo-Json)
          
          $i = az provider show --namespace "Microsoft.AzureActiveDirectory" --query "registrationState" -o tsv
          $j = az rest --method POST --url https://management.azure.com/subscriptions/${{ parameters.SubscriptionID }}/providers/Microsoft.AzureActiveDirectory/checkNameAvailability?api-version=2019-01-01-preview --body "@B2CDetails.json" --query 'reason' -o tsv
          

          if ($i -eq "$(AADProvider)" -and $j -eq "$(AADExists)") {
            echo "###############################################################"
            echo "Provider $(AADProvider) and Name $(AADExists)"
            echo "###############################################################"
            exit 1
            }
          
          elseif ($i -eq "$(AADProvider)" -or $j -eq "$(AADExists)") {
            echo "###############################################################"
            echo "Either Name $(AADExists) or Provider $(AADProvider)"
            echo "###############################################################"
            exit 1
            }
          else {
            echo "###############################################################"
            echo "MOVE TO NEXT STAGE - DEPLOY AZURE AAD B2C"
            echo "###############################################################"
            }

```

| POWERSHELL MODULE (ValidateAADB2C.ps1): IF ANYONE INTENDS TO VALIDATE USING POWERSHELL ONLY (MINUS DEVOPS PIPELINE):- | 
| --------- |

```
$AADExists          = "AlreadyExists"
$AADProvider        = "NotRegistered"
$AADB2CCountryCode  = "CH"
$AADB2CName         = "AMTestb2ctenant005.onmicrosoft.com"
$AADB2CRest         = "https://management.azure.com/subscriptions/210e66cb-55cf-424e-8daa-6cad804ab604/providers/Microsoft.AzureActiveDirectory/checkNameAvailability?api-version=2019-01-01-preview"

$B2CJSON = @{
      countryCode   = "$AADB2CCountryCode"
      name          = "$AADB2CName"
    }
$infile = "B2CDetails.json"
Set-Content -Path $infile -Value ($B2CJSON | ConvertTo-Json)

$i = az rest --method POST --url $AADB2CRest  --body "@B2CDetails.json" --query 'reason' -o tsv

$j = az provider show --namespace "Microsoft.AzureActiveDirectory" --query "registrationState" -o tsv

if ($i -eq "$AADExists" -and $j -eq "$AADProvider") {
Write-Output "Name $AADExists and Provider $AADProvider"
}

ElseIf ($i -eq "$AADExists" -or $j -eq "$AADProvider") {
Write-Output "Either Name $AADExists or Provider $AADProvider"
}

Else {
Write-Output "MOVE TO NEXT STAGE - DEPLOY AZURE AAD B2C"
}

```
Now, let me explain each part of YAML Pipeline for better understanding.

| PART #1:- | 
| --------- |

| BELOW FOLLOWS PIPELINE RUNTIME VARIABLES CODE SNIPPET:- | 
| --------- |

```
######################
#DECLARE PARAMETERS:-
######################
parameters:
- name: SubscriptionID
  displayName: Subscription ID Details Follow Below:-
  default: 210e66cb-55cf-424e-8daa-6cad804ab604
  values:
  -  210e66cb-55cf-424e-8daa-6cad804ab604

- name: ServiceConnection
  displayName: Service Connection Name Follows Below:-
  default: amcloud-cicd-service-connection
  values:
  -  amcloud-cicd-service-connection

- name: AADB2CName
  displayName: Please Provide the AAD B2C Tenant Name:-
  type: object
  default: <Please Provide the Name of AAD B2C>
```

| THIS IS HOW IT LOOKS WHEN YOU EXECUTE THE PIPELINE FROM AZURE DEVOPS:- | 
| --------- |

| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/978tc5smywldhc1owwol.png) | 
| --------- |

| NOTE:- | 
| --------- |

| Please Provide the Name of B2C in the Format - __[NAME].onmicrosoft.com__ | 
| --------- |
| For Example: __AMTestb2ctenant005.onmicrosoft.com__ |

| PART #2:- | 
| --------- |

| BELOW FOLLOWS PIPELINE VARIABLES CODE SNIPPET:- | 
| --------- |

```
######################
#DECLARE VARIABLES:-
######################
variables:
  AADExists: AlreadyExists
  AADProvider: NotRegistered
  BuildAgent: windows-latest

```

| NOTE:- | 
| --------- |

| Please feel free to change the values of the variables. | 
| --------- |
| The entire YAML pipeline is build using Parameters and variables. No Values are Hardcoded. |

| PART #3:- | 
| --------- |

| BELOW FOLLOWS PIPELINE STAGE __VALIDATE_AAD_B2C_PROVIDER_AND_NAME__ CODE SNIPPET:- | 
| --------- |

```
###################
# Declare Stages:-
###################
stages:

- stage: VALIDATE_AAD_B2C_PROVIDER_AND_NAME
   
  jobs:
  - job: IF_AAD_B2C_PROVIDER_AND_NAME_EXISTS 
    displayName: IF AAD B2C PROVIDER AND NAME EXISTS
    steps:
    - task: AzureCLI@2
      displayName: CHECK AAD B2C PROVIDER AND NAME
      inputs:
        azureSubscription: ${{ parameters.ServiceConnection }}
        scriptType: ps
        scriptLocation: inlineScript
        inlineScript: |
          az --version
          az account set --subscription ${{ parameters.SubscriptionID }}
          az account show  
          $B2CJSON = @{
              countryCode = "CH"
              name = "${{ parameters.AADB2CName }}" 
            }
          $infile = "B2CDetails.json"
          Set-Content -Path $infile -Value ($B2CJSON | ConvertTo-Json)
          
          $i = az provider show --namespace "Microsoft.AzureActiveDirectory" --query "registrationState" -o tsv
          $j = az rest --method POST --url https://management.azure.com/subscriptions/${{ parameters.SubscriptionID }}/providers/Microsoft.AzureActiveDirectory/checkNameAvailability?api-version=2019-01-01-preview --body "@B2CDetails.json" --query 'reason' -o tsv
          

          if ($i -eq "$(AADProvider)" -and $j -eq "$(AADExists)") {
            echo "###############################################################"
            echo "Provider $(AADProvider) and Name $(AADExists)"
            echo "###############################################################"
            exit 1
            }
          
          elseif ($i -eq "$(AADProvider)" -or $j -eq "$(AADExists)") {
            echo "###############################################################"
            echo "Either Name $(AADExists) or Provider $(AADProvider)"
            echo "###############################################################"
            exit 1
            }
          else {
            echo "###############################################################"
            echo "MOVE TO NEXT STAGE - DEPLOY AZURE AAD B2C"
            echo "###############################################################"
            }

```
| ## | CONDITIONS APPLIED IN VALIDATE STAGE | 
| --------- | --------- |
| 1. | Firstly, it validates whether the Provider __Microsoft.AzureActiveDirectory__ is Registered in the Subscription. If the Value returned is __NotRegistered__ it means that condition is __Not Met__ to Deploy B2C. __az cli__ is used to validate the Registration of the Provider in the Subscription. |
| 2. | Secondly, it validates whether the B2C Name Provided by the User is Globally Unique. If the Value returned is __AlreadyExists__ it means that the condition is __Not Met__ to Deploy B2C. __REST API__ together with __AZ REST__ is used to validate B2C Globally Unique Name.   |
| 3. | Expected value for __Provider__ and __B2C Name__ are: __Registered__ and __Null__ |


| __TEST CASES:-__ | 
| --------- |

| __TEST CASE #1:__ B2C NAME IS GLOBALLY __NOT UNIQUE__ AND PROVIDER REGISTERED IN THE SUBSCRIPTION :- | 
| --------- |
| __Desired Output:__ __VALIDATE__ Stage __FAILS__  |
| __PIPELINE RUNTIME VARIABES:-__ |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/zb5sfh603ssocd4ihjsv.png) |
| __PIPELINE RESULTS:-__ |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/k718wwqij7p4x0bmhr26.png) |



| __TEST CASE #2:__ B2C NAME IS GLOBALLY __UNIQUE__ AND PROVIDER REGISTERED IN THE SUBSCRIPTION:- | 
| --------- |
| __Desired Output:__ __VALIDATE__ Stage Executes __SUCCESSFULLY__.|
| __PIPELINE RUNTIME VARIABES:-__ |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/2ayqv35jb2zacdwffig7.png) |
| __PIPELINE RESULTS:-__ |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/y9jm939fzjugfdqqbw83.png) |


| __USE CASE #2:-__ |
| --------- |
| Validate If Azure B2C Tenant Deployment is Possible using Terraform and DevOps |


| __QUICK ANSWER:-__ |
| --------- |
| Azure B2C Tenant Deployment is __Not Possible__ to deploy using Terraform and DevOps Together.|
| Azure B2C Tenant Deployment is __Possible__ to deploy using Terraform only (By Manually Executing Terraform __Init__, __Plan__ and __Deploy__) |


| __PIPELINE DETAILS FOLLOW BELOW:-__ |
| --------- |

1. This is a __Two Stage__ Pipeline with 2 Runtime Variables - 1) Subscription ID 2) Service Connection Name  
2. The Stages Performs Terraform __INIT__, __PLAN__ and __DEPLOY__ 

| __HOW DOES MY CODE PLACEHOLDER LOOKS LIKE:-__ |
| --------- |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/8ocr0d29ru13cjudezd7.png) |

| __DETAILS AND ALL CODE SNIPPETS FOLLOWS BELOW:-__ |
| --------- |


| TERRAFORM (main.tf):- | 
| --------- |

```
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.2"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.20.0"
    }
    
  }
}
provider "azurerm" {
  features {}
  skip_provider_registration = true
}

```

| TERRAFORM (b2c.tf):- | 
| --------- |

```
## AAD B2C:-
resource "azurerm_aadb2c_directory" "Az_B2c" {
  country_code            = var.b2c-country-code
  data_residency_location = var.b2c-data-loc
  display_name            = var.b2c-name
  domain_name            = "${var.b2c-name}.onmicrosoft.com"
  resource_group_name     = var.b2c-rg
  sku_name                = var.b2c-sku
}

```

| TERRAFORM (variables.tf):- | 
| --------- |

```
variable "b2c-name" {
  type        = string
  description = "Name of the B2C Tenant"
}

variable "b2c-country-code" {
  type        = string
  description = "Country Code of B2C"
}

variable "b2c-data-loc" {
  type        = string
  description = "Data Residency Location of B2C"
}

variable "b2c-rg" {
  type        = string
  description = "Resource Group of B2C"
}

variable "b2c-sku" {
  type        = string
  description = "Resource Group of B2C"
}

```

| TERRAFORM (b2c.tfvars):- | 
| --------- |

```
b2c-country-code    = "CH"
b2c-data-loc        = "Europe"
b2c-name           = "AMTestb2ctenant005"
b2c-rg              = "_Admin-rg"
b2c-sku             = "PremiumP1"

```
| NOTE:- |
| --------- |
| You may have noticed that I have put "**b2c-name**" as __AMTestb2ctenant005__. Please Refer __Use Case #1, Test Case #2__, where I have Validated this Name.   |


| AZURE DEVOPS YAML PIPELINE (azure-pipelines-B2C-v1.1.yml):- | 
| --------- |

```
trigger:
  none

######################
#DECLARE PARAMETERS:-
######################
parameters:
- name: SubscriptionID
  displayName: Subscription ID Details Follow Below:-
  default: 210e66cb-55cf-424e-8daa-6cad804ab604
  values:
  -  210e66cb-55cf-424e-8daa-6cad804ab604

- name: ServiceConnection
  displayName: Service Connection Name Follows Below:-
  default: amcloud-cicd-service-connection
  values:
  -  amcloud-cicd-service-connection

######################
#DECLARE VARIABLES:-
######################
variables:
  ResourceGroup: tfpipeline-rg
  StorageAccount: tfpipelinesa
  Container: terraform
  TfstateFile: B2C/b2cdeploy.tfstate
  BuildAgent: windows-latest
  WorkingDir: $(System.DefaultWorkingDirectory)/B2C-Terraform
  Target: $(build.artifactstagingdirectory)/AMTF
  Environment: NonProd
  Artifact: AM

#########################
# Declare Build Agents:-
#########################
pool:
  vmImage: $(BuildAgent)

###################
# Declare Stages:-
###################
stages:

- stage: PLAN
  jobs:
  - job: PLAN
    displayName: PLAN
    steps:
# Install Terraform Installer in the Build Agent:-
    - task: ms-devlabs.custom-terraform-tasks.custom-terraform-installer-task.TerraformInstaller@0
      displayName: INSTALL TERRAFORM VERSION - LATEST
      inputs:
        terraformVersion: 'latest'
# Terraform Init:-
    - task: TerraformTaskV2@2
      displayName: TERRAFORM INIT
      inputs:
        provider: 'azurerm'
        command: 'init'
        workingDirectory: '$(workingDir)' # Az DevOps can find the required Terraform code
        backendServiceArm: '${{ parameters.ServiceConnection }}' 
        backendAzureRmResourceGroupName: '$(ResourceGroup)' 
        backendAzureRmStorageAccountName: '$(StorageAccount)'
        backendAzureRmContainerName: '$(Container)'
        backendAzureRmKey: '$(TfstateFile)'
# Terraform Validate:-
    - task: TerraformTaskV2@2
      displayName: TERRAFORM VALIDATE
      inputs:
        provider: 'azurerm'
        command: 'validate'
        workingDirectory: '$(workingDir)'
        environmentServiceNameAzureRM: '${{ parameters.ServiceConnection }}'
# Terraform Plan:-
    - task: TerraformTaskV2@2
      displayName: TERRAFORM PLAN
      inputs:
        provider: 'azurerm'
        command: 'plan'
        workingDirectory: '$(workingDir)'
        commandOptions: "--var-file=b2c.tfvars --out=tfplan"
        environmentServiceNameAzureRM: '${{ parameters.ServiceConnection }}'
    
# Copy Files to Artifacts Staging Directory:-
    - task: CopyFiles@2
      displayName: COPY FILES ARTIFACTS STAGING DIRECTORY
      inputs:
        SourceFolder: '$(workingDir)'
        Contents: |
          **/*.tf
          **/*.tfvars
          **/*tfplan*
        TargetFolder: '$(Target)'
# Publish Artifacts:-
    - task: PublishBuildArtifacts@1
      displayName: PUBLISH ARTIFACTS
      inputs:
        targetPath: '$(Target)'
        artifactName: '$(Artifact)' 

- stage: DEPLOY
  condition: succeeded()
  dependsOn: PLAN
  jobs:
  - deployment: 
    displayName: Deploy
    environment: $(Environment)
    pool:
      vmImage: '$(BuildAgent)'
    strategy:
      runOnce:
        deploy:
          steps:
# Download Artifacts:-
          - task: DownloadBuildArtifacts@0
            displayName: DOWNLOAD ARTIFACTS
            inputs:
              buildType: 'current'
              downloadType: 'single'
              artifactName: '$(Artifact)'
              downloadPath: '$(System.ArtifactsDirectory)' 
# Install Terraform Installer in the Build Agent:-
          - task: ms-devlabs.custom-terraform-tasks.custom-terraform-installer-task.TerraformInstaller@0
            displayName: INSTALL TERRAFORM VERSION - LATEST
            inputs:
              terraformVersion: 'latest'
# Terraform Init:-
          - task: TerraformTaskV2@2 
            displayName: TERRAFORM INIT
            inputs:
              provider: 'azurerm'
              command: 'init'
              workingDirectory: '$(System.ArtifactsDirectory)/$(Artifact)/AMTF/' # Az DevOps can find the required Terraform code
              backendServiceArm: '${{ parameters.ServiceConnection }}' 
              backendAzureRmResourceGroupName: '$(ResourceGroup)' 
              backendAzureRmStorageAccountName: '$(StorageAccount)'
              backendAzureRmContainerName: '$(Container)'
              backendAzureRmKey: '$(TfstateFile)'
# Terraform Apply:-
          - task: TerraformTaskV2@2
            displayName: TERRAFORM APPLY # The terraform Plan stored earlier is used here to apply only the changes.
            inputs:
              provider: 'azurerm'
              command: 'apply'
              workingDirectory: '$(System.ArtifactsDirectory)/$(Artifact)/AMTF'
              commandOptions: '--var-file=b2c.tfvars' # The terraform Plan stored earlier is used here to apply. 
              environmentServiceNameAzureRM: '${{ parameters.ServiceConnection }}'

```
Now, let me explain each part of YAML Pipeline for better understanding.

| PART #1:- | 
| --------- |

| BELOW FOLLOWS PIPELINE RUNTIME VARIABLES CODE SNIPPET:- | 
| --------- |

```
######################
#DECLARE PARAMETERS:-
######################
parameters:
- name: SubscriptionID
  displayName: Subscription ID Details Follow Below:-
  default: 210e66cb-55cf-424e-8daa-6cad804ab604
  values:
  -  210e66cb-55cf-424e-8daa-6cad804ab604

- name: ServiceConnection
  displayName: Service Connection Name Follows Below:-
  default: amcloud-cicd-service-connection
  values:
  -  amcloud-cicd-service-connection

```
| THIS IS HOW IT LOOKS WHEN YOU EXECUTE THE PIPELINE FROM AZURE DEVOPS:- | 
| --------- |

| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/hlzyh0rwo4bxy68gqmvf.png) | 
| --------- |


| PART #2:- | 
| --------- |

| BELOW FOLLOWS PIPELINE VARIABLES CODE SNIPPET:- | 
| --------- |

```
######################
#DECLARE VARIABLES:-
######################
variables:
  ResourceGroup: tfpipeline-rg
  StorageAccount: tfpipelinesa
  Container: terraform
  TfstateFile: B2C/b2cdeploy.tfstate
  BuildAgent: windows-latest
  WorkingDir: $(System.DefaultWorkingDirectory)/B2C-Terraform
  Target: $(build.artifactstagingdirectory)/AMTF
  Environment: NonProd
  Artifact: AM

```
| NOTE:- | 
| --------- |

| Please feel free to change the values of the variables. | 
| --------- |
| The entire YAML pipeline is build using Parameters and variables. No Values are Hardcoded. |
| "**Working Directory**" Path should be based on your Code Placeholder. |
| "**Environment**" here refers to Pipeline Environment Name where Approval Gate is configured. |


| PART #3:- | 
| --------- |

| ## | TASKS PERFORMED UNDER __PLAN__ STAGE | 
| --------- | --------- |
| 1. | Install Latest Version of Terraform in Build Agent |
| 2. | Terraform Init |
| 3. | Terraform Validate |
| 4. | Terraform Plan |
| 5. | Copy Files to Artifacts Staging Directory |
| 6. | Publish Artifacts |


| NOTE:- |
| --------- |

```
- task: ms-devlabs.custom-terraform-tasks.custom-terraform-installer-task.TerraformInstaller@0

```
| Explanation:- |
| --------- |
| Instead of using __TerraformInstaller@0__ YAML Task, I have specified the Full Name. This is because I have Multiple Terraform Extensions in my DevOps Organisation and with each of the terraform Extension exists the Terraform Install Task |

| PART #4:- | 
| --------- |

| ## | TASKS PERFORMED UNDER __DEPLOY__ STAGE | 
| --------- | --------- |
| 1. | Previous Stage __PLAN__ should complete Successfully in order for this Stage __DEPLOY__ to Proceed. Otherwise, the Stage will get skipped |
| 2. | Download Published Artifacts |
| 3. | Terraform Init |
| 4. | Terraform Apply |


| __TEST CASES:-__ | 
| --------- |

| __TEST CASE #1:__ B2C NAME IS GLOBALLY __NOT UNIQUE__ AND PROVIDER REGISTERED IN THE SUBSCRIPTION :- | 
| --------- |
| __Desired Output:__ __PLAN__ Stage is __SUCCESSFUL__ but __DEPLOY__ Stage __FAILS__  |
| __PIPELINE RESULTS:-__ |
| Waiting for Approval |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/qaf78eun4zmth03jnsfm.png) |
| __DEPLOY__ Stage __FAILED__ |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/goqs9uxindpssymmy14v.png) |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/ajjh0967tax12dx85cvj.png) |

| __ERROR ENCOUNTERED:-__ | 
| --------- |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/wiy6h19u2b4fwygkdy23.png) |

| __REASON:-__ | 
| --------- |
| It occurs when using a Service Principal. When creating an Azure B2C directory, the user who creates it becomes the owner of the new directory by default. This is achieved by the user account being added to the B2C directory as an External Member from the parent directory.
Service Principals cannot be added as external members of other directories, therefore it's __NOT POSSIBLE__ for a Service Principal to create a B2C directory |
| The Issue is Recorded in Github - https://github.com/hashicorp/terraform-provider-azurerm/issues/14941 |

| __DEPLOY AZURE B2C USING TERRAFORM ONLY (By Manually Executing Terraform Init, Plan and Deploy) :-__ | 
| --------- |

| __COMMANDS:-__ |
| --------- |

```
terraform init
```

```
terraform plan --var-file="b2c.tfvars"
```

```
terraform apply --var-file="b2c.tfvars"
```

| __OUTPUT:-__ |
| --------- |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/zdkn3ypwobfzfkzjhh01.png) |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/ujwlpz81z3uwvu5qwp3h.png) |

| __HOW DOES THE PLACEHOLDER LOOKS LIKE AFTER TERRAFORM EXECUTION :-__ |
| --------- |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/dfos3mv7o21y9ewxft8j.png) |
