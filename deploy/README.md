```
SUFFIX=<>

az login

az account set --subscription "<>"

az group create -l japaneast -n rg-$SUFFIX

az deployment group create --resource-group rg-$SUFFIX --template-file main.bicep --parameters main.parameters.json
```
