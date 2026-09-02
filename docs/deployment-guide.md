# Deployment guide

This guide separates bootstrap, infrastructure, and content deployment. Use a dedicated target subscription and an identity with only the permissions required for each phase.

## 1. Choose private deployment values

Before running Terraform, choose and record these values outside the public repository:

- Azure subscription and Microsoft Entra tenant IDs.
- Azure region with available Fabric F2 capacity.
- Globally unique Dev and Prod capacity names without hyphens.
- Globally unique Terraform state storage account name.
- Azure DevOps organization, project, and repository names.
- Human owners for approvals, access reviews, cost control, and credential rotation.

Copy `docs/live-environment.example.md` to a private location for the deployed inventory. Never complete it in the public repository.

## 2. Prerequisites

- Terraform 1.11 or later, Azure CLI, Git, and Python 3.11 or later.
- Azure subscription permission to create resource groups, storage, Fabric capacities, networking, and role assignments.
- Microsoft Entra permission to create groups, applications, service principals, and federated credentials.
- Fabric tenant administrator for the narrowly scoped tenant settings described in [manual-actions.md](manual-actions.md).
- Azure DevOps project administrator for repositories, service connections, variable groups, environments, pipelines, and branch policies.
- User Access Administrator or an equivalent custom role at the target Azure scopes. Subscription Owner is not required.

Confirm capacity SKU and regional availability before applying. A successful Terraform plan does not reserve regional capacity.

## 3. Validate locally

```bash
python -m venv .venv
source .venv/bin/activate
python -m pip install --requirement requirements.txt
python tests/validate_repo.py

terraform -chdir=terraform/bootstrap init -backend=false
terraform -chdir=terraform/bootstrap fmt -check -recursive
terraform -chdir=terraform/bootstrap validate

terraform -chdir=terraform/environments/dev init -backend=false
terraform -chdir=terraform/environments/dev fmt -check -recursive
terraform -chdir=terraform/environments/dev validate

terraform -chdir=terraform/environments/prod init -backend=false
terraform -chdir=terraform/environments/prod fmt -check -recursive
terraform -chdir=terraform/environments/prod validate
```

## 4. Bootstrap state and identities

Copy the bootstrap example to the ignored filename and replace every placeholder:

```bash
cp terraform/bootstrap/terraform.tfvars.example terraform/bootstrap/terraform.tfvars
az login --tenant <tenant-id>
az account set --subscription <subscription-id>

terraform -chdir=terraform/bootstrap init
terraform -chdir=terraform/bootstrap plan -out=bootstrap.tfplan
terraform -chdir=terraform/bootstrap apply bootstrap.tfplan
terraform -chdir=terraform/bootstrap output -json
```

Bootstrap creates private Terraform state, Dev and Prod resource groups, the three Entra security groups, plan/apply/content service principals without client secrets, and scoped Azure RBAC.

Review the plan before apply. The state endpoint is private by default; complete the private agent/network path before moving routine pipeline execution to the remote backend.

## 5. Configure Azure DevOps authentication

Create these Azure Resource Manager service connections with Microsoft Entra workload identity federation:

| Connection | Identity | Intended access |
|---|---|---|
| `sc-fabric-plan` | plan service principal | State lock access, resource-group Reader, Fabric Viewer |
| `sc-fabric-apply` | apply service principal | State Blob Contributor, resource-group Contributor, Fabric Workspace Admin |
| `sc-fabric-content` | content service principal | Resource-group Reader, Fabric Workspace Contributor, deployment-pipeline Admin |

Authorize each service connection only for the pipelines that use it. Do not grant access to all pipelines. Add each generated issuer and subject as a federated credential on its matching application.

## 6. Create variable groups and environments

Create `fabric-shared`, `fabric-dev`, and `fabric-prod` from [variable-libraries.md](variable-libraries.md).

Create these Azure DevOps Environments:

- `fabric-dev-infrastructure`
- `fabric-prod-infrastructure`
- `fabric-dev-content`
- `fabric-prod-content`

Require approval for both infrastructure environments and `fabric-prod-content`. Add an exclusive sequential lock so Terraform and Fabric releases cannot overlap.

## 7. Import into Azure DevOps Repos

1. Create a private Azure DevOps project and repository.
2. Import your repository created from this GitHub template.
3. Create `develop` from `main` and a concrete `feature/<name>` branch from `develop`.
4. Protect `main` and `develop` with reviewers, comment resolution, and `terraform-plan.yml` build validation.
5. Treat Azure DevOps as the operational source after import. Avoid bidirectional unsynchronized changes between GitHub and Azure DevOps.

## 8. Enable Fabric tenant settings

Scope these settings to dedicated groups as described in [manual-actions.md](manual-actions.md):

- Service principals can create workspaces, connections, and deployment pipelines.
- Service principals can call Fabric public APIs.
- Users can synchronize workspace items with Git repositories.

Do not enable service-principal access for the entire tenant.

## 9. Create the Fabric Azure DevOps configured connection

Create an Azure DevOps source-control connection in Fabric using an authorized identity. Grant it only the required repository access and store its connection ID as protected variable `FABRIC_GIT_CONNECTION_ID`.

For a brand-new workspace connection, set `enable_git_integration=true` only for the reviewed creation apply. If the connection was created through the Fabric API or portal, leave it `false`: the provider can create `fabric_workspace_git` but cannot currently import an existing connection.

## 10. Apply Dev

Copy `terraform/environments/dev/terraform.tfvars.example` to the ignored `terraform.tfvars`, replace every placeholder, then initialize the remote backend:

```bash
terraform -chdir=terraform/environments/dev init \
  -backend-config="resource_group_name=<state-resource-group>" \
  -backend-config="storage_account_name=<state-storage-account>" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=dev.tfstate"
terraform -chdir=terraform/environments/dev plan -out=dev.tfplan
terraform -chdir=terraform/environments/dev apply dev.tfplan
```

The optional private agent requires a real SSH public key plus the state resource-group and storage-account inputs. Keep `enable_private_agent=false` if your organization provides an approved agent with access to the private state endpoint.

## 11. Apply Prod

Copy and populate the Prod example. Use the Dev workspace ID output when assigning the deployment pipeline:

```bash
terraform -chdir=terraform/environments/prod init \
  -backend-config="resource_group_name=<state-resource-group>" \
  -backend-config="storage_account_name=<state-storage-account>" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=prod.tfstate"
terraform -chdir=terraform/environments/prod plan -out=prod.tfplan
terraform -chdir=terraform/environments/prod apply prod.tfplan
```

## 12. Register pipelines

Create Azure Pipelines from:

- `pipelines/terraform-plan.yml`
- `pipelines/terraform-apply.yml`
- `pipelines/fabric-deploy.yml`

Authorize only their required variable groups, service connections, and environments. Run validation before any apply. F2 capacities are billable, so retain manual approval for creation and changes.

Pull-request plans deliberately use `-refresh=false`; Fabric requires Workspace Admin to read workspace role assignments. The approved apply job always creates a fresh live plan before changing resources.

## 13. Verify

Confirm that:

- Dev and Prod capacities are active and assigned to the intended workspaces.
- Developers are Contributor in Dev/Feature and Viewer in Prod.
- Dev Git status is synchronized with `develop` under `/fabric-git-items`.
- The deployment pipeline contains Dev Stage and Prod Stage.
- All seven Git-owned demo items exist in Dev and Prod.
- `BankingConfig` has DEV active in Dev and PROD active in Prod.
- No secret or completed deployment inventory appears in source, state output, plans, artifacts, or logs.

## 14. Operate safely

- Pause capacities when the demonstration is idle if continuous availability is unnecessary.
- Rotate configured-connection credentials on your organization's schedule.
- Review RBAC and approvals periodically.
- Keep Terraform state private and versioned.
- Add schedules only through a reviewed change; this template configures none.
