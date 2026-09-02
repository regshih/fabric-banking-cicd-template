resource "fabric_workspace_git" "this" {
  workspace_id            = var.workspace_id
  initialization_strategy = "PreferRemote"

  git_provider_details = {
    git_provider_type = "AzureDevOps"
    organization_name = var.organization_name
    project_name      = var.project_name
    repository_name   = var.repository_name
    branch_name       = var.branch_name
    directory_name    = var.directory_name
  }

  git_credentials = {
    source        = "ConfiguredConnection"
    connection_id = var.connection_id
  }

  options = {
    allow_override_items = false
  }
}
