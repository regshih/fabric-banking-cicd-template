# Deployment inventory template

Copy this file to a private operating repository or secure documentation system after deployment. Do not commit real tenant, subscription, identity, workspace, connection, storage, or pipeline identifiers to a public repository.

## Source control

| Resource | Value |
|---|---|
| Azure DevOps organization | `<organization>` |
| Azure DevOps project | `<project>` |
| Operational repository | `<repository>` |
| Protected branches | `main`, `develop` |
| Feature branch | `feature/<name>` |

## Azure and Fabric

| Resource | Value |
|---|---|
| Subscription | `<subscription-name>` / `<subscription-id>` |
| Tenant | `<tenant-id>` |
| Region | `<azure-region>` |
| Dev capacity | `<dev-capacity-name>` / `<fabric-capacity-id>` |
| Prod capacity | `<prod-capacity-name>` / `<fabric-capacity-id>` |
| Dev workspace | `Fabric-Dev` / `<workspace-id>` |
| Feature workspace | `Fabric-Feature` / `<workspace-id>` |
| Prod workspace | `Fabric-Prod` / `<workspace-id>` |
| Deployment pipeline | `Fabric Banking Dev-Prod` / `<pipeline-id>` |
| Fabric Git connection | `<connection-name>` / `<connection-id>` |

## Identity and access

Record the object IDs for `FabricAdmins`, `FabricDevelopers`, `FabricAutomation`, and the plan, apply, and content service principals in your private inventory. Record role scopes and the owners responsible for periodic access review.

## Terraform state and agent

| Resource | Value |
|---|---|
| State resource group | `<state-resource-group>` |
| Storage account | `<state-storage-account>` |
| Container | `tfstate` |
| State keys | `bootstrap.tfstate`, `dev.tfstate`, `prod.tfstate` |
| Agent pool | `<private-agent-pool>` |
| Agent | `<agent-name>` |

## Evidence and operations

Record successful plan, apply, content deployment, and promotion run links privately. Also record capacity pause/resume ownership, configured-connection credential rotation dates, and any approved schedules.

No recurring schedules are configured by this template.
