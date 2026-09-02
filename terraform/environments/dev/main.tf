locals {
  tags = {
    environment         = "dev"
    workload            = var.workload_name
    owner               = var.owner
    data-classification = "synthetic"
    managed-by          = "terraform"
  }

  capacity_admins = setunion(
    var.capacity_admin_members,
    toset([var.apply_service_principal_id])
  )

  dev_role_assignments = {
    admins = {
      principal_id   = var.fabric_admin_group_id
      principal_type = "Group"
      role           = "Admin"
    }
    developers = {
      principal_id   = var.fabric_developer_group_id
      principal_type = "Group"
      role           = "Contributor"
    }
    plan = {
      principal_id   = var.plan_service_principal_id
      principal_type = "ServicePrincipal"
      role           = "Viewer"
    }
    platform = {
      principal_id   = var.apply_service_principal_id
      principal_type = "ServicePrincipal"
      role           = "Admin"
    }
    content = {
      principal_id   = var.content_service_principal_id
      principal_type = "ServicePrincipal"
      role           = "Contributor"
    }
  }
}

module "capacity" {
  source = "../../modules/capacity"

  resource_group_name    = var.resource_group_name
  location               = var.location
  capacity_name          = var.capacity_name
  sku_name               = "F2"
  administration_members = local.capacity_admins
  tags                   = local.tags
}

module "workspace" {
  source = "../../modules/workspace"

  display_name     = "Fabric-Dev"
  description      = "Development workspace for the synthetic banking analytics CI/CD POC."
  capacity_id      = var.fabric_capacity_id
  role_assignments = local.dev_role_assignments

  depends_on = [module.capacity]
}

module "workspace_git" {
  count  = var.enable_git_integration ? 1 : 0
  source = "../../modules/workspace-git"

  workspace_id      = module.workspace.workspace_id
  organization_name = var.azure_devops_organization
  project_name      = var.azure_devops_project
  repository_name   = var.azure_devops_repository
  branch_name       = "develop"
  directory_name    = "/fabric-git-items"
  connection_id     = var.fabric_git_connection_id
}

module "feature_workspace" {
  count  = var.enable_feature_workspace ? 1 : 0
  source = "../../modules/workspace"

  display_name     = "Fabric-Feature"
  description      = "Optional feature workspace for isolated Fabric development."
  capacity_id      = var.fabric_capacity_id
  role_assignments = local.dev_role_assignments

  depends_on = [module.capacity]
}

module "feature_workspace_git" {
  count  = var.enable_feature_workspace && var.enable_git_integration ? 1 : 0
  source = "../../modules/workspace-git"

  workspace_id      = module.feature_workspace[0].workspace_id
  organization_name = var.azure_devops_organization
  project_name      = var.azure_devops_project
  repository_name   = var.azure_devops_repository
  branch_name       = var.feature_branch
  directory_name    = "/fabric-git-items"
  connection_id     = var.fabric_git_connection_id
}

module "private_agent" {
  count  = var.enable_private_agent ? 1 : 0
  source = "../../modules/private-agent"

  resource_group_name = var.resource_group_name
  location            = var.location
  storage_account_id  = "/subscriptions/${var.subscription_id}/resourceGroups/${var.state_resource_group_name}/providers/Microsoft.Storage/storageAccounts/${var.state_storage_account_name}"
  ssh_public_key      = var.agent_ssh_public_key
  vm_size             = var.agent_vm_size
  tags                = local.tags
}
