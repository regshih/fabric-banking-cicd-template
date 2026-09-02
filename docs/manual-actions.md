# Manual actions and operating decisions

The repository automates infrastructure and Fabric content, but tenant-wide and organization-wide controls require an authorized administrator.

## Azure DevOps setup

Create a private Azure DevOps project and repository, then configure:

- `main`, `develop`, and one concrete `feature/<name>` branch.
- The three YAML pipelines under `pipelines/`.
- The three variable groups documented in [variable-libraries.md](variable-libraries.md).
- Four protected environments and their approval checks.
- Three workload-identity service connections.
- Reviewer, comment-resolution, and validation-build policies on `main` and `develop`.

Do not store PATs, client secrets, or configured-connection credentials in repository files or non-secret variables.

## Fabric tenant settings

Create or reuse a narrowly scoped `FabricAutomation` security group containing only the approved automation service principals.

In the Fabric Admin portal:

1. Under **Developer settings**, enable **Service principals can create workspaces, connections, and deployment pipelines** for `FabricAutomation` only.
2. Under **Developer settings**, enable **Service principals can call Fabric public APIs** for `FabricAutomation` only.
3. Under **Git integration settings**, enable **Users can synchronize workspace items with their Git repositories** for the approved automation, administrator, and developer groups.
4. Apply each setting and verify it with the intended service principal.

Do not enable service-principal settings for the entire tenant.

## Private state connectivity

Terraform state storage disables public network access and shared-key authentication. Select one approved execution model:

- Enable the included private agent module and register the resulting VM as an Azure Pipelines agent.
- Use an existing organization-managed agent that can resolve and reach the state private endpoint.
- Modify the backend network design only after a security review.

The repository provisions agent infrastructure but intentionally does not place an Azure DevOps registration token in cloud-init or Terraform state. Register the agent through your approved bootstrap process and rotate any one-time token immediately afterward.

## Recurring decisions

- Approve infrastructure and production content releases after reviewing the exact commit and plan.
- Pause the two F2 capacities when idle if availability is not required.
- Rotate the Fabric configured-connection credential according to policy.
- Review workspace membership, service-principal access, environment approvers, and branch policies.
- Decide whether your workload requires drift checks, refresh schedules, backup, monitoring, or repository synchronization.

## Scheduling

No recurring schedules are configured by this template. All pipeline triggers are pull-request, branch, or manual events.
