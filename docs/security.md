# Security model

## Identity separation

| Identity | Azure role | Fabric role | Purpose |
|---|---|---|---|
| Plan service principal | Reader on Dev/Prod RG; Blob Data Contributor on state (lock only) | Viewer | State-based PR plans; state lock acquisition requires blob write permission. Live refresh is deferred to approved apply. |
| Apply service principal | Contributor on Dev/Prod RG; Blob Data Contributor on state | Workspace Admin | Infrastructure lifecycle and workspace RBAC |
| Content service principal | Reader on Dev/Prod RGs only (required to initialize the subscription-scoped WIF service connection) | Workspace Contributor; deployment-pipeline Admin | Item deployment, Variable Library activation, promotion |
| `FabricAdmins` | None by default | Workspace Admin | Human administration and break-glass recovery |
| `FabricDevelopers` | None by default | Dev/Feature Contributor; Prod Viewer | Development without Prod mutation |

Role assignment creation requires User Access Administrator or an equivalent custom role during bootstrap. Don't grant permanent subscription Owner to pipeline identities.

## Authentication

- Use Microsoft Entra issuer workload identity federation for Azure DevOps service connections.
- Keep each service connection explicitly authorized to named pipelines.
- Don't create client secrets unless a documented platform limitation blocks federation.
- Fabric tenant service-principal settings should target a dedicated security group, not the entire tenant.

## Data controls

- All included banking data is deterministic and synthetic.
- The notebook explicitly excludes names, emails, SSNs, and account numbers.
- Terraform tags Azure resources with `data-classification=synthetic`.
- Real FSI data requires a separate threat model, data residency review, Purview/sensitivity classification, private connectivity assessment, audit retention, and regulatory approval.
- Viewer access is not a substitute for row-level, column-level, or object-level security.

## Secrets and state

- `.tfvars`, state, plans, environment files, and private keys are ignored.
- State storage disables shared-key authentication, anonymous container access, and public network access.
- State has versioning and 30-day soft delete.
- Azure DevOps secret variables or Key Vault-linked variable groups are required if any future connection needs a secret.
- Never output access tokens, connection secrets, or full Terraform state in pipeline logs.
- PR plans use `-refresh=false` because Fabric requires Workspace Admin to read role assignments. This prevents untrusted PR validation from receiving an administrator identity; the manually approved apply job performs a fresh live plan before applying.

## Pipeline controls

- Require PR validation on `develop` and `main`.
- Require production reviewers who aren't the change author.
- Use Azure DevOps Environment exclusive locks with sequential execution.
- Keep `allow_override_items=false` for Fabric Git Integration.
- Treat unpublishing orphaned Fabric items as destructive; `deploy_fabric.py` requires an explicit `--remove-orphans` flag and pipelines don't set it.

## POC limitations

This repository demonstrates engineering controls; it isn't evidence of PCI DSS, GLBA, SOX, FFIEC, OCC, or internal-bank-policy compliance. F2 capacities and the service connectivity model need architecture review before use with regulated data.
