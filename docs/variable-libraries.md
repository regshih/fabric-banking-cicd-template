# Variable Libraries and Azure DevOps variable groups

Two similarly named features are used for different purposes.

## Fabric Variable Library

`fabric-items/BankingConfig.VariableLibrary` is deployed into each workspace.

| Variable | DEV value | PROD value | Secret? |
|---|---|---|---|
| `SQL_ENDPOINT` | Target Dev Lakehouse SQL endpoint | Target Prod Lakehouse SQL endpoint | No |
| `LAKEHOUSE_ID` | Target Dev Lakehouse item ID | Target Prod Lakehouse item ID | No |
| `ENVIRONMENT` | `DEV` | `PROD` | No |

`fabric-cicd` replaces target-specific IDs and endpoints. The active set is not stored in Git, so `set_active_value_set.py` calls the Fabric Variable Library API and `verify_fabric.py` confirms it.

Never put passwords, tokens, private keys, or customer data in a Fabric Variable Library.

## Azure DevOps variable groups

Create these groups in Pipelines → Library.

### `fabric-shared`

| Variable | Example |
|---|---|
| `AZURE_SUBSCRIPTION_ID` | Target subscription GUID |
| `AZURE_TENANT_ID` | Target tenant GUID |
| `TFSTATE_RESOURCE_GROUP` | Private state resource group |
| `TFSTATE_STORAGE_ACCOUNT` | Globally unique private state account |
| `TFSTATE_CONTAINER` | `tfstate` |
| `AGENT_POOL_NAME` | Approved private Azure Pipelines pool |
| `WORKLOAD_NAME` | `fabric-banking-cicd` or your workload tag |
| `RESOURCE_OWNER` | Owning team or cost-center tag |
| `FABRIC_DEPLOYMENT_PIPELINE_NAME` | `Fabric Banking Dev-Prod` |
| `FABRIC_ADMIN_GROUP_ID` | Bootstrap output |
| `FABRIC_DEVELOPER_GROUP_ID` | Bootstrap output |
| `PLAN_SERVICE_PRINCIPAL_OBJECT_ID` | Bootstrap output |
| `APPLY_SERVICE_PRINCIPAL_OBJECT_ID` | Bootstrap output |
| `CONTENT_SERVICE_PRINCIPAL_OBJECT_ID` | Bootstrap output |
| `CAPACITY_ADMIN_MEMBER` | Approved capacity-admin UPN; currently the tenant administrator |
| `ENABLE_FEATURE_WORKSPACE` | `true` for this full POC |
| `FEATURE_BRANCH` | `feature/banking-demo` |
| `PLAN_SERVICE_CONNECTION` | `sc-fabric-plan` |
| `APPLY_SERVICE_CONNECTION` | `sc-fabric-apply` |
| `CONTENT_SERVICE_CONNECTION` | `sc-fabric-content` |

### `fabric-dev`

| Variable | Value |
|---|---|
| `FABRIC_WORKSPACE_ID` | Terraform Dev output |
| `FABRIC_CAPACITY_ID` | Fabric service GUID for the Dev capacity |
| `RESOURCE_GROUP_NAME` | Dev resource group created by bootstrap |
| `CAPACITY_NAME` | Globally unique Dev capacity resource name |
| `ENABLE_GIT_INTEGRATION` | `false` for this adopted live connection; `true` only when Terraform creates a new connection |
| `AZDO_ORGANIZATION` | Organization name |
| `AZDO_PROJECT` | Project name |
| `AZDO_REPOSITORY` | Your Azure DevOps repository name |
| `FABRIC_GIT_CONNECTION_ID` | Configured Fabric connection ID; mark secret to reduce log exposure |

### `fabric-prod`

| Variable | Value |
|---|---|
| `FABRIC_WORKSPACE_ID` | Terraform Prod output |
| `FABRIC_CAPACITY_ID` | Fabric service GUID for the Prod capacity |
| `RESOURCE_GROUP_NAME` | Prod resource group created by bootstrap |
| `CAPACITY_NAME` | Globally unique Prod capacity resource name |
| `ENABLE_GIT_INTEGRATION` | `false` |
| `AZDO_ORGANIZATION` | Organization name |
| `AZDO_PROJECT` | Project name |
| `AZDO_REPOSITORY` | Your Azure DevOps repository name |
| `FABRIC_GIT_CONNECTION_ID` | Empty/not used by Prod |

Authorize each variable group only for the pipelines that consume it.
