# contoso-air

A sample airline booking application used for demos and learning purposes.

This repository is a revived and modernized version of the previously archived [microsoft/ContosoAir](https://github.com/microsoft/ContosoAir) demo project. This version has been updated with current technology standards including Node.js 22, Azure CosmosDB with MongoDB API 7.0, and modern authentication via Azure Managed Identity. While maintaining its original purpose, the codebase now features a completely refreshed infrastructure.

To get started, follow the setup instructions below, which will guide you through configuring the necessary Azure resources and running the application 
locally.

## Prerequisites

- Node.js 22.0.0 or later
- Azure CLI
- POSX-compliant shell (i.e., bash or zsh)

## Getting Started

Create an Azure CosmosDB account and export the account name and access key as environment variables:

```bash
# create random resource identifier
RAND=$RANDOM
export RAND
echo "Random resource identifier will be: ${RAND}"

# set variables
AZURE_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
AZURE_RESOURCE_GROUP_NAME=rg-contosoair$RAND
AZURE_COSMOS_ACCOUNT_NAME=db-contosoair$RAND
AZURE_REGION=eastus

# create resource group
az group create \
--name $AZURE_RESOURCE_GROUP_NAME \
--location $AZURE_REGION

# create cosmosdb account
AZURE_COSMOS_ACCOUNT_ID=$(az cosmosdb create \
--name $AZURE_COSMOS_ACCOUNT_NAME \
--resource-group $AZURE_RESOURCE_GROUP_NAME \
--kind MongoDB \
--server-version 7.0 \
--query id -o tsv)

# create test database
az cosmosdb mongodb database create \
  --account-name $AZURE_COSMOS_ACCOUNT_NAME \
  --resource-group $AZURE_RESOURCE_GROUP_NAME \
  --name test

# create managed identity
AZURE_COSMOS_IDENTITY_ID=$(az identity create \
--name db-contosoair$RAND-id \
--resource-group $AZURE_RESOURCE_GROUP_NAME \
--query id -o tsv)

# get managed identity principal id
AZURE_COSMOS_IDENTITY_PRINCIPAL_ID=$(az identity show \
--ids $AZURE_COSMOS_IDENTITY_ID \
--query principalId \
-o tsv)

# assign role to managed identity
az role assignment create \
--role "DocumentDB Account Contributor" \
--assignee $AZURE_COSMOS_IDENTITY_PRINCIPAL_ID \
--scope $AZURE_COSMOS_ACCOUNT_ID

# export variables for azure identity auth
export AZURE_COSMOS_CLIENTID=$(az identity show \
--ids $AZURE_COSMOS_IDENTITY_ID \
--query clientId \
-o tsv)
export AZURE_COSMOS_LISTCONNECTIONSTRINGURL=https://management.azure.com/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$AZURE_RESOURCE_GROUP_NAME/providers/Microsoft.DocumentDB/databaseAccounts/$AZURE_COSMOS_ACCOUNT_NAME/listConnectionStrings?api-version=2021-04-15
export AZURE_COSMOS_SCOPE=https://management.azure.com/.default
```

Clone the repository then run the following commands:

```bash
# change directory
cd src/web

# install dependencies
npm install

# run the app
npm start
```

Browse to `http://localhost:3000` to see the app.

## Azure MCP for Copilot Coding Agent

This repository is configured to work with the Azure MCP (Model Context Protocol) server for GitHub Copilot coding agent integration. The setup enables seamless connection between Copilot and Azure services such as Azure Cosmos DB and Azure Storage.

### Configuration Files

- `.github/workflows/copilot-setup-steps.yml` - GitHub Actions workflow for Azure authentication
- `.mcp.json` - MCP server configuration for Azure services

### Required Secrets

To use the Azure MCP integration, configure the following secrets in your repository's Copilot environment:

- `AZURE_CLIENT_ID` - Azure AD application client ID
- `AZURE_TENANT_ID` - Azure AD tenant ID  
- `AZURE_SUBSCRIPTION_ID` - Azure subscription ID

### OIDC Setup

Before using the Azure MCP, you must configure OIDC in a Microsoft Entra application to trust GitHub. Follow the guide: [Use the Azure Login action with OpenID Connect](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure-openid-connect).

## Cleanup

```bash
az group delete --name $AZURE_RESOURCE_GROUP_NAME --yes --no-wait
```
