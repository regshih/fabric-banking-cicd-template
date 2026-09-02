resource "fabric_deployment_pipeline" "this" {
  display_name = var.display_name
  description  = "Promotes the synthetic banking analytics solution from Dev to Prod."

  stages = [
    {
      display_name = "Dev Stage"
      description  = "Validated development content"
      is_public    = false
      workspace_id = var.dev_workspace_id
    },
    {
      display_name = "Prod Stage"
      description  = "Approved production-demo content"
      is_public    = false
      workspace_id = var.prod_workspace_id
    }
  ]
}

resource "fabric_deployment_pipeline_role_assignment" "administrator" {
  for_each = var.administrator_principal_ids

  deployment_pipeline_id = fabric_deployment_pipeline.this.id
  principal = {
    id   = each.value
    type = "ServicePrincipal"
  }
  role = "Admin"
}
