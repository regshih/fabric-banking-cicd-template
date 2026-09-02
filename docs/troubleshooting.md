# Troubleshooting

## Fabric capacity can't be created

Symptoms: `CapacityProvisioningFailed`, regional allocation failure, or SKU unavailable.

1. Confirm `Microsoft.Fabric` is registered.
2. Confirm West US 3 still supports Fabric and F2 allocation.
3. Check whether the exact capacity name already exists in the resource group.
4. Don't silently deploy to another region; update the approved plan first.
5. Remember that successful Terraform planning doesn't reserve regional capacity.

## Fabric provider can't list the capacity

- Ensure the capacity is Active, not paused.
- Ensure the caller can read the capacity and Fabric tenant.
- This POC deliberately supplies the known capacity GUID and uses `skip_capacity_state_validation=true` so the PR plan identity does not need Fabric capacity-admin permissions. PR plans use protected state without live refresh; the approved apply identity performs the fresh live plan.

## Service principal receives 401/403 from Fabric

- Confirm the tenant setting allows the service principal's security group to call Fabric public APIs.
- Confirm the identity has the required workspace role.
- Deployment promotion also requires deployment-pipeline Admin.
- Confirm Azure CLI in the `AzureCLI@2` task is logged in as the intended service connection.
- Confirm Fabric, Azure DevOps, and the app registration use compatible tenants.

## Git Integration fails

- `fabric_workspace_git` supports service principals only with `ConfiguredConnection`.
- Verify the connection ID belongs to the target tenant and Azure DevOps repository.
- Verify the service principal is an Azure DevOps organization user with repository permissions.
- Directory names must begin with `/`; this repo's native Git connection uses `/fabric-git-items`.
- Fabric needs a concrete branch; don't use `feature/*` as the configured branch.

## Terraform apply identity can't create resources

- Bootstrap must create the environment resource groups and Contributor role assignments first.
- Role propagation can take several minutes; rerun after confirming the assignment exists.
- Plan and apply identities are intentionally different.
- The apply identity isn't Owner and can't grant arbitrary RBAC; workspace role assignments use Fabric APIs, while Azure RBAC bootstrap stays separate.

## Remote state authentication fails

- Confirm both plan and apply identities have Storage Blob Data Contributor on the state account. Terraform plans acquire and release a state lock, so Blob Data Reader is insufficient even for read-only infrastructure planning.
- Confirm shared-key authentication isn't being attempted.
- In Azure Pipelines, verify `addSpnToEnvironment: true` and the OIDC backend settings are present.
- Check that state account, container, and key names match the variable group.
- If your state account is private-only, Microsoft-hosted agents will receive a network/403 failure even with correct RBAC. Use the private pool named by `AGENT_POOL_NAME` and verify DNS resolution, routing, and private endpoint approval.

## Deployment promotion reports `TargetArtifactNameConflict`

Fabric can lose stage-item pairing when Git-owned definitions are updated directly with `fabric-cicd`, even though same-named target items already exist. The approved Prod job handles only this exact Fabric error by deploying the reviewed Git definitions directly to Prod, then activates and verifies the PROD variable set. Any other deployment-pipeline error remains fatal. The initial Dev-to-Prod deployment-pipeline promotion is retained as the POC proof; the fallback keeps subsequent releases idempotent while Fabric item pairing evolves.

## Fabric item deployment fails

Run offline validation first:

```bash
python tests/validate_repo.py
```

Then check:

- Item type supports the Fabric public APIs and service principal.
- `.platform` contains a unique, stable logical ID.
- JSON is valid and TMDL indentation wasn't converted to spaces accidentally.
- The Notebook, Pipeline, and Variable Library placeholders are handled by `parameter.yml`.
- Lakehouse data isn't expected to appear from Git alone; run `IngestTransactions`.

## Wrong Variable Library values

The active value set isn't stored in Git. Run:

```bash
python pipelines/scripts/set_active_value_set.py --workspace-id <guid> --value-set DEV
python pipelines/scripts/verify_fabric.py --workspace-id <guid> --expected-value-set DEV
```

Use `PROD` only in `Fabric-Prod`.

## Deployment pipeline promotion fails

- Confirm Dev and Prod workspaces are assigned to the expected stages.
- Confirm the content identity is pipeline Admin and Contributor or higher in both workspaces.
- Confirm every selected item type supports service-principal deployment.
- Review the Fabric operation returned through the LRO `Location` URL.
- A target Variable Library must retain the active value-set name; don't delete/rename an active set during promotion.
