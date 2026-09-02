locals {
  tags = {
    environment         = "prod"
    workload            = var.workload_name
    owner               = var.owner
    data-classification = "synthetic"
    managed-by          = "terraform"
  }

  capacity_admins = setunion(
    var.capacity_admin_members,
    toset([var.apply_service_principal_id])
  )

  prod_role_assignments = {
    admins = {
      principal_id   = var.fabric_admin_group_id
      principal_type = "Group"
      role           = "Admin"
    }
    developers = {
      principal_id   = var.fabric_developer_group_id
      principal_type = "Group"
      role           = "Viewer"
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

  display_name     = "Fabric-Prod"
  description      = "Production-demo workspace for the synthetic banking analytics CI/CD POC."
  capacity_id      = var.fabric_capacity_id
  role_assignments = local.prod_role_assignments

  depends_on = [module.capacity]
}

module "deployment_pipeline" {
  source = "../../modules/deployment-pipeline"

  display_name      = "Fabric Banking Dev-Prod"
  dev_workspace_id  = var.dev_workspace_id
  prod_workspace_id = module.workspace.workspace_id
  administrator_principal_ids = toset([
    var.apply_service_principal_id,
    var.content_service_principal_id,
  ])
}
