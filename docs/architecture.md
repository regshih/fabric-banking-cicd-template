# Architecture

## Logical view

```mermaid
flowchart TB
    subgraph SCM[Source control and CI]
        GH[Public GitHub template]
        ADO[Azure DevOps operational repository]
        PR[Branch policies and PR validation]
        TFPlan[Terraform plan pipeline]
        TFApply[Terraform apply pipeline]
        Content[Fabric content pipeline]
        GH -->|create from template and import| ADO
        ADO --> PR --> TFPlan
        ADO --> TFApply
        ADO --> Content
    end

    subgraph Identity[Microsoft Entra ID]
        Admins[FabricAdmins]
        Developers[FabricDevelopers]
        PlanSP[Plan workload identity]
        ApplySP[Apply workload identity]
        ContentSP[Content workload identity]
    end

    subgraph Dev[Development boundary]
        DevRG[Configurable Dev resource group]
        DevCapacity[Globally unique Dev F2 capacity]
        DevWorkspace[Fabric-Dev]
        FeatureWorkspace[Fabric-Feature optional]
        DevRG --> DevCapacity --> DevWorkspace
        DevCapacity --> FeatureWorkspace
    end

    subgraph Prod[Production-demo boundary]
        ProdRG[Configurable Prod resource group]
        ProdCapacity[Globally unique Prod F2 capacity]
        ProdWorkspace[Fabric-Prod]
        ProdRG --> ProdCapacity --> ProdWorkspace
    end

    Pipeline[Fabric Deployment Pipeline\nDev Stage → Prod Stage]
    DevWorkspace --> Pipeline --> ProdWorkspace
    TFApply --> DevRG
    TFApply --> ProdRG
    Content --> DevWorkspace
    Content --> Pipeline
    Admins --> DevWorkspace
    Admins --> ProdWorkspace
    Developers -->|Contributor| DevWorkspace
    Developers -->|Viewer| ProdWorkspace
    PlanSP -->|Reader / Viewer| DevRG
    ApplySP -->|Contributor / Workspace Admin| DevRG
    ContentSP -->|Workspace Contributor / Pipeline Admin| Pipeline
```

## Ownership boundaries

| Layer | Owner | State/source of truth |
|---|---|---|
| Bootstrap resource groups, state backend, groups, app registrations | Terraform bootstrap stack | Private Azure Storage, `bootstrap.tfstate` |
| Capacities, workspaces, access, deployment pipeline | Environment Terraform roots | Private Azure Storage, separate `dev.tfstate` and `prod.tfstate` keys |
| Existing Dev/Feature workspace Git connections | Fabric API/portal | Live Fabric connection metadata; Terraform creation is disabled because the provider cannot import an existing connection |
| Fabric item definitions | Azure DevOps Git | `fabric-items/` |
| Native Fabric Git smoke-test definition | Azure DevOps Git | `fabric-git-items/` |
| Fabric item data | Fabric/OneLake | Generated or ingested data, never Git |
| Environment values | Fabric Variable Library | Definition in Git; active value set is workspace state |
| Approvals | Azure DevOps Environments | Azure DevOps configuration |

## Deployment sequence

```mermaid
sequenceDiagram
    participant D as Developer
    participant R as Azure DevOps Repo
    participant CI as Validation Pipeline
    participant FD as Fabric-Dev
    participant A as Prod Approver
    participant DP as Fabric Deployment Pipeline
    participant FP as Fabric-Prod

    D->>R: Push feature branch and open PR
    R->>CI: Validate Terraform, JSON/YAML, Fabric structure
    CI-->>R: Required status check
    D->>R: Merge to develop
    R->>FD: fabric-cicd publish and DEV value set activation
    FD-->>CI: Verify seven required items
    D->>R: Merge release PR to main
    CI->>A: Azure DevOps Environment approval
    A-->>CI: Approve
    CI->>DP: Deploy Dev Stage to Prod Stage
    alt Fabric stage-item pairing is valid
        DP->>FP: Promote supported content
    else TargetArtifactNameConflict only
        CI->>FP: Deploy the same approved Git definitions directly
    end
    CI->>FP: Activate PROD value set and verify
```

## Design choices

- Dev and Prod use different capacities and resource groups to contain blast radius and access.
- The feature workspace shares the dev F2 capacity to control POC cost.
- Prod isn't connected to an independently editable Git branch. The approved Prod job normally uses the Fabric Deployment Pipeline; only `TargetArtifactNameConflict` invokes the verified direct deployment of the same reviewed Git definitions.
- The report's semantic model contains a small embedded synthetic KPI table so deployment can be validated before data refresh. The Lakehouse notebook provides the operational synthetic dataset and can replace the embedded partition with Direct Lake in a later iteration.
