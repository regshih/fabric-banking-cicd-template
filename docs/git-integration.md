# Fabric Git Integration

## Branch mapping

| Branch | Workspace/use |
|---|---|
| `main` | Released source and production approval trigger |
| `develop` | Connected to `Fabric-Dev` |
| `feature/<name>` | Connected to optional `Fabric-Feature` one concrete branch at a time |

Fabric requires a concrete branch name; `feature/*` is a branch policy pattern, not a value accepted by the workspace connection.

## Connect a workspace

Terraform uses `fabric_workspace_git` with:

- Provider: `AzureDevOps`
- Initialization: `PreferRemote`
- Directory: `/fabric-git-items`
- Credentials: `ConfiguredConnection`

The native workspace connection intentionally uses a small Git smoke-test item. The full banking item set remains under `fabric-items/` and is deployed by the validated `fabric-cicd` pipeline. This hybrid boundary avoids coupling the release path to item types whose native Git dependency serialization is still evolving, while retaining a live bidirectional Git integration proof.
- Overrides: disabled

Prerequisites:

1. Add the service principal to the Azure DevOps organization and project.
2. Grant repository read/contribute permissions without bypass-policy permission.
3. Create the Fabric Azure DevOps source-control connection.
4. Supply only its connection ID to Terraform.

The provider currently has no import implementation for `fabric_workspace_git`. If a connection already exists, keep `ENABLE_GIT_INTEGRATION=false` and manage that connection through the Fabric API/portal; otherwise Terraform will plan a new resource that it cannot adopt. Set the flag to `true` only when Terraform will create a brand-new connection.

`PreferRemote` is intentional: Git is authoritative during initial connection. The pipeline never enables `allow_override_items` automatically.

## Sync from Git

1. Open Workspace settings → Git integration.
2. Review incoming and outgoing changes.
3. Select Update all only after confirming the expected commit and affected items.
4. For automation, use the Git Update From Git API under the content service principal.
5. Verify Git status becomes Synced and item dependencies point to items in the same workspace.

Git updates item definitions, not Lakehouse table/file data.

## Commit from Fabric

1. Make the change in `Fabric-Feature` or `Fabric-Dev`; never author directly in Prod.
2. Review the item-level diff in Source control.
3. Use a focused commit message and avoid bundling unrelated workspace changes.
4. Push to a feature branch and open a pull request to `develop`.
5. Ensure `.platform` logical IDs remain stable across renames.

## Resolve conflicts

1. Stop automated sync for the affected workspace.
2. Pull both the workspace diff and remote branch locally.
3. Resolve JSON/TMDL/PBIR changes in Git; don't choose “overwrite all” as the first response.
4. Validate JSON/YAML and run `python tests/validate_repo.py`.
5. Commit the resolution to the feature branch.
6. Update the workspace from Git and verify Synced status.

For a rename, preserve the existing `.platform` `logicalId`. If two independently created items represent the same intended item, select one logical ID and explicitly remove the duplicate after backing up both definitions.

## GitHub and Azure DevOps

The private GitHub repository is the delivered project location. Azure DevOps is the operational repository for Fabric commits and Azure Pipelines after the initial import. Avoid bidirectional unsupervised mirroring: it can create divergent histories and accidental force pushes. If the organization wants GitHub backup, implement a protected, one-way Azure DevOps→GitHub synchronization identity with no force-push permission.
