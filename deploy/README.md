```
POSTFIX=20230418temp

az login

az account set --subscription "<>"

az group create -l japaneast -n rg-$POSTFIX

az deployment group create --resource-group rg-$POSTFIX --template-file main.bicep
```
