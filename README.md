# Sign and release

## Repo structure

```
root
 |
 ├─── pipeline-scripts
 |        Script used in GitHub pipeline
 |
 └─── scripts
         Main folder for scripts
```

## Script signing

Scripts are automatically signed by a GitHub action workflow. The workflow triggers on commits to main branch, limited to file changes in /scripts/**.

Azuresigntool.exe is used to sign the scripts. [AzureSignTool](https://github.com/vcsjones/AzureSignTool)

## Azure identity

Access to the signing certificate is provided through a Managed Identity and OIDC workload federation.

| Identity | Permissions | Description
|--|--|--|
| mi-github-script-signing | kv-example-01: [custom] Key Vault Crypto User | Custom rbac role combining *Key Vault Reader* and *Key Vault Crypto User*

## GitHub secrets

| Secret | Content description |
|--|--|
| AZURE_CLIENT_ID | The managed identity client ID |
| AZURE_SUBSCRIPTION_ID | The managed identity subscription ID |
| AZURE_TENANT_ID | Entra tenant ID |
