# How to deploy
## Set parameters and login
```
SUFFIX=<>
LOC=japaneast

az login

az account set --subscription "<>"
```
### Create resource group if it doesn't exist already
```
az group create -l $LOC -n rg-$SUFFIX
```
### Deploy the Bicep template
```
az deployment group what-if --resource-group rg-$SUFFIX --template-file main.bicep --parameters @main.parameters.json

az deployment group create --resource-group rg-$SUFFIX --template-file main.bicep --parameters @main.parameters.json
```